import torch
import torch.nn as nn
from torch.nn import functional as F
from torch.utils.data import Dataset, DataLoader

from tqdm import tqdm
import logging
import pandas as pd

import os
import sys

mean = [
    773.01792745,
    -88.91943195,
    257.42027559,
    318.24409449,
    324.74732846,
    334.68848425,
    340.11283746,
    307.42055681,
]
std = [
    497.12221911,
    253.92590509,
    272.79684578,
    19.25624324,
    45.58375268,
    43.85550165,
    36.24868204,
    41.05464977,
]


class NMSLTestDataset(Dataset):
    def __init__(self, data_path: str, file: str):
        self.data = []
        self.labels = []

        with open(os.path.join(data_path, file), "r") as f:
            this_data = []
            for line in f.readlines()[:-1]:
                line = line.strip().split(" ")
                v = [(int(s) - mean[i]) / std[i] for i, s in enumerate(line[:])]

                if len(this_data) < 5:
                    this_data.append(v)
                else:
                    self.data.append(torch.tensor(this_data, dtype=torch.float).T)
                    this_data.pop(0)
                    this_data.append(v)

                    self.labels.append([ord(i) - ord("a") for i in file.split(".")[0]])

    def __getitem__(self, index):
        return self.data[index], self.labels[index]

    def __len__(self):
        return len(self.data)


# define model
# define model
class Classifier(nn.Module):
    def __init__(self):
        super(Classifier, self).__init__()
        # QuantStub converts tensors from floating point to quantized
        self.quant = torch.quantization.QuantStub()
        self.conv = torch.nn.Conv1d(8, 10, 3)
        self.batchnorm = torch.nn.BatchNorm1d(10)

        self.flatten = torch.nn.Flatten()
        # self.relu = torch.nn.ReLU()
        self.linear = torch.nn.Linear(10 * 3, 27)
        # DeQuantStub converts tensors from quantized to floating point
        self.dequant = torch.quantization.DeQuantStub()

    def forward(self, x):
        # manually specify where tensors will be converted from floating
        # point to quantized in the quantized model
        x = self.quant(x)
        x = self.conv(x)
        x = self.batchnorm(x)
        x = self.flatten(x)
        x = self.linear(x)
        # manually specify where tensors will be converted from quantized
        # to floating point in the quantized model
        x = self.dequant(x)
        return x


# class Classifier(nn.Module):
#     def __init__(self):
#         super().__init__()
#         # self.cnn = nn.Sequential(
#         #     nn.Conv1d(8, 15, 2),
#         #     nn.Flatten(),
#         # )
#         self.fc1 = nn.Sequential(
#             nn.Flatten(),
#             nn.Linear(8 * 4, 15 * 3),
#             nn.ReLU(),
#         )

#         self.fc = nn.Sequential(
#             nn.Linear(15 * 3, 27),
#         )

#     def forward(self, x):
#         output = self.fc1(x)
#         output = self.fc(output)
#         return output


if __name__ == "__main__":
    path = sys.argv[1]
    d, f = "/".join(path.split("/")[:-1]), path.split("/")[-1]
    test_set = NMSLTestDataset(d, f)
    test_loader = DataLoader(test_set, batch_size=1, shuffle=False)

    device = "cpu"
    model_fp32 = Classifier().to(device)

    # model must be set to eval mode for static quantization logic to work
    model_fp32.eval()

    # attach a global qconfig, which contains information about what kind
    # of observers to attach. Use 'fbgemm' for server inference and
    # 'qnnpack' for mobile inference. Other quantization configurations such
    # as selecting symmetric or assymetric quantization and MinMax or L2Norm
    # calibration techniques can be specified here.
    model_fp32.qconfig = torch.quantization.get_default_qconfig("fbgemm")

    # Fuse the activations to preceding layers, where applicable.
    # This needs to be done manually depending on the model architecture.
    # Common fusions include `conv + relu` and `conv + batchnorm + relu`
    model_fp32_fused = torch.quantization.fuse_modules(
        model_fp32, [["conv", "batchnorm"]]
    )

    # Prepare the model for static quantization. This inserts observers in
    # the model that will observe activation tensors during calibration.
    model_fp32_prepared = torch.quantization.prepare(model_fp32_fused)
    model_fp32_prepared.load_state_dict(torch.load("model_quantize.pth"))

    model_int8 = torch.quantization.convert(model_fp32_prepared)

    df_LM = pd.read_csv("./bigram.csv")
    LM = {row["word"].upper(): row["prob"] for i, row in df_LM.iterrows()}

    seq = " "
    table = {}

    cnt = 0
    prev_topN = None
    prev_topN_prob = None
    start = True

    with torch.no_grad():
        for batch in test_loader:
            inputs, labels = batch
            inputs = inputs.to(device)

            output_res = model_int8(inputs)

            # output_prob = F.softmax(output_res, dim=1)
            # print(output_prob, output_res)
            output_prob = output_res
            pred = torch.argsort(output_prob, 1, descending=True)[0][:2]
            pred = sorted(pred)

            topN = [chr(i.cpu().detach() + ord("A")) if i <= 25 else " " for i in pred]
            topN_prob = [output_prob[0][i.cpu().detach()] for i in pred]
            # print(
            #     [chr(i.cpu().detach() + ord("A")) for i in pred],
            #     [output_res[0][i.cpu().detach()] for i in pred],
            # )

            if topN == prev_topN:
                print(prev_topN, cnt)
                cnt += 1
                prev_topN_prob = [
                    prev + this for prev, this in zip(prev_topN_prob, topN_prob)
                ]
                if start:
                    cnt = 0
            elif cnt > 5:
                prev_topN_prob = [i / cnt for i in prev_topN_prob]
                cnt = 0
                print(prev_topN, prev_topN_prob)

                if table == {}:
                    for i, char in enumerate(prev_topN):
                        table[char] = LM[f" {char}"] * prev_topN_prob[i]
                else:
                    tmp_table = {}
                    for i, char in enumerate(prev_topN):
                        this_seq = ""
                        this_prob = -1

                        # if prev_topN_prob[i] < 25000:
                        #     continue

                        for s, p in table.items():
                            # print(this_seq, s, p)
                            if p * LM[s[-1] + char] * prev_topN_prob[i] > this_prob:
                                this_seq = s + char
                                this_prob = p * LM[s[-1] + char] * prev_topN_prob[i]

                            # print(char, s, this_seq, this_prob)
                        tmp_table[this_seq] = this_prob

                    table = tmp_table

                prev_topN = topN
                prev_topN_prob = topN_prob
            else:
                print(prev_topN, cnt, topN)
                cnt = 0
                if prev_topN is not None:
                    start = False
                prev_topN = topN
                prev_topN_prob = topN_prob

    print(table)
