import torch
import torch.nn as nn
from torch.nn import functional as F
from torch.utils.data import Dataset, DataLoader
import numpy as np

from tqdm import tqdm
import logging
import pandas as pd

import os

logger = logging.getLogger(__name__)

config = {
    "batch_size": 16,
}

# Novel Multi Sign Language Dataset
class NMSLDataset(Dataset):
    def __init__(self, data_path: str):
        data = []
        labels = []

        speakers = os.listdir(data_path)

        for i in speakers:
            labeled_data_files = os.listdir(os.path.join(data_path, i))
            for file in labeled_data_files:
                with open(os.path.join(data_path, i, file), "r") as f:
                    for line in f.readlines()[:-1]:
                        line = line.strip().split(" ")
                        v = [int(i) for i in line[:]]

                        data.append(v)
                        if file[0] in [chr(ord("A") + i) for i in range(26)]:
                            labels.append(torch.tensor(ord(file[0]) - ord("A")))
                        elif "halt" in file:
                            labels.append(torch.tensor(26))
                        elif "random" in file:
                            labels.append(torch.tensor(27))

        data = np.array(data)
        # normalize data
        self.mean = np.mean(data, axis=0)
        self.std = np.std(data, axis=0)
        data = (data - np.mean(data, axis=0)) / np.std(data, axis=0)

        self.data = []
        self.labels = []

        this_data = []
        this_label = -1
        for i, v in enumerate(data):
            if len(this_data) < 5:
                this_data.append(v)
                this_label = labels[i]
            else:
                self.data.append(torch.tensor(this_data, dtype=torch.float).T)
                self.labels.append(torch.tensor(this_label))

                if labels[i] != this_label:
                    this_data = []
                    this_label = -1
                    continue
                else:
                    this_data.pop(0)
                    this_data.append(v)

    def __getitem__(self, index):
        return self.data[index], self.labels[index]

    def __len__(self):
        return len(self.data)


# define model
class Classifier(nn.Module):
    def __init__(self):
        super().__init__()
        self.cnn = nn.Sequential(
            nn.Conv1d(8, 10, 3),
            nn.BatchNorm1d(10),
            nn.Flatten(),
        )

        self.fc = nn.Sequential(
            nn.Linear(10 * 3, 27),
            # nn.ReLU(),
            # nn.Linear(30, 27),
        )

    def forward(self, x):
        output = self.cnn(x)
        output = self.fc(output)
        return output


if __name__ == "__main__":
    train_set = NMSLDataset("dataset/train")
    train_loader = DataLoader(train_set, batch_size=config["batch_size"], shuffle=True)

    device = "cuda" if torch.cuda.is_available() else "cpu"

    model = Classifier().to(device)
    criterion = nn.CrossEntropyLoss()

    optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

    for epoch in range(50):
        model.train()

        train_acc = 0
        train_loss = 0

        with tqdm(train_loader, desc=f"Epoch {epoch + 1}") as tepoch:
            for batch in tepoch:
                inputs, labels = batch
                inputs = inputs.to(device)
                labels = labels.to(device)

                outputs = model(inputs)
                loss = criterion(outputs, labels)

                _, train_pred = torch.max(outputs, 1)
                loss.backward()
                optimizer.step()

                train_acc += (train_pred.cpu() == labels.cpu()).sum().item()
                train_loss = loss.item()

                tepoch.set_postfix(loss=train_loss)

            print(f"Train Accuracy: {train_acc / len(train_set)}")

    torch.save(model.state_dict(), "model.pth")
    print(f"mean: {train_set.mean}")
    print(f"std: {train_set.std}")
