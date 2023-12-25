from eval import Classifier
import serial
import time
import sys
import os
import pandas as pd

import torch

# COM=input("Enter the COM Port\n")
# BAUD=input("Enter the Baudrate\n")

port = sys.argv[1] if len(sys.argv) > 1 else "COM12"

SerialPort = serial.Serial(port, 115200, timeout=1)

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

start_time = time.time()
normalization = []

print("start normalizing...")
while time.time() - start_time < 3:
    SerialPort.write(b"1")
    IncomingData = SerialPort.readline()
    if IncomingData:
        # print((IncomingData).decode("utf-8"))
        normalization.append(IncomingData.decode("utf-8"))

threshold = [0] * 5

for data in normalization:
    nums = str(data).split(" ")
    for i in range(5):
        threshold[i] += int(nums[i + 3])

print(threshold)
threshold = [int(i / len(normalization)) - 300 for i in threshold]

model = Classifier()
model.load_state_dict(torch.load("./model.pth", map_location=torch.device("cpu")))
model.eval()
df_LM = pd.read_csv("./bigram.csv")
LM = {row["word"].upper(): row["prob"] for i, row in df_LM.iterrows()}


queue = []

table = {}
cnt = 0
prev_topN = None
prev_topN_prob = None
start = True

print(
    "start!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
)

while True:
    try:
        with torch.no_grad():
            SerialPort.write(b"1")
            IncomingData = SerialPort.readline()
            IncomingData = IncomingData.decode("utf-8")

            IncomingData = [int(i) for i in IncomingData.split()]
            if IncomingData == []:
                continue

            for i in range(5):
                IncomingData[i + 3] = IncomingData[i + 3] - threshold[i]

            # print(IncomingData)
            data = [(v - mean[i]) / std[i] for i, v in enumerate(IncomingData)]
            if data != []:
                # print("data", data)
                queue.append(data)

            if len(queue) < 5:
                continue
            else:
                # print(queue)
                input_data = torch.tensor(queue, dtype=torch.float).T.unsqueeze(0)
                queue.pop(0)
                # print("input:", input_data)
                try:
                    res = model(input_data)
                except:
                    print(input_data, queue)
                # print(res)
                pred = torch.argsort(res, 1, descending=True)[0][:2]
                pred = sorted(pred)

                topN = [
                    chr(i.cpu().detach() + ord("A")) if i <= 25 else " " for i in pred
                ]
                topN_prob = [res[0][i.cpu().detach()] for i in pred]

            if topN == prev_topN:
                # print(prev_topN, cnt)
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

                print(table)

                prev_topN = topN
                prev_topN_prob = topN_prob
            else:
                # print(prev_topN, cnt, topN)
                cnt = 0
                if prev_topN is not None:
                    start = False
                prev_topN = topN
                prev_topN_prob = topN_prob
    except KeyboardInterrupt:
        SerialPort.close()
        sys.exit(0)
