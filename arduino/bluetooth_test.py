import serial
import time
import sys
import os

# COM=input("Enter the COM Port\n")
# BAUD=input("Enter the Baudrate\n")

SerialPort = serial.Serial("COM12", 115200, timeout=1)


start_time = time.time()
normalization = []

print("start normalizing...")
while time.time() - start_time < 3:
  SerialPort.write(b'1')
  IncomingData = SerialPort.readline()
  if(IncomingData):
    # print((IncomingData).decode('utf-8'))
    normalization.append(IncomingData.decode('utf-8'))

threshold_1 = 0
threshold_2 = 0
threshold_3 = 0
threshold_4 = 0
threshold_5 = 0

for data in normalization:
  nums = str(data).split(' ')
  threshold_1 = threshold_1 + int(nums[3])
  threshold_2 = threshold_2 + int(nums[4])
  threshold_3 = threshold_3 + int(nums[5])
  threshold_4 = threshold_4 + int(nums[6])
  threshold_5 = threshold_5 + int(nums[7])

threshold_1 = threshold_1 / len(normalization)
threshold_2 = threshold_2 / len(normalization)
threshold_3 = threshold_3 / len(normalization)
threshold_4 = threshold_4 / len(normalization)
threshold_5 = threshold_5 / len(normalization)

threshold_1 = int(threshold_1) - 300
threshold_2 = int(threshold_2) - 300
threshold_3 = int(threshold_3) - 300
threshold_4 = int(threshold_4) - 300
threshold_5 = int(threshold_5) - 300

while True:
  try:
    filename = input('> ')
    f_out = open(filename + "_raw.txt", "w")

    start_time = time.time()
    while time.time() - start_time < 30:
      try:
        SerialPort.write(b'1')
        IncomingData = SerialPort.readline()
        if(IncomingData):
          print((IncomingData).decode('utf-8'))
          f_out.write((IncomingData).decode('utf-8'))    
        
      except KeyboardInterrupt:
        break

    f_out.close()

    f_in = open(filename + "_raw.txt", "r")

    with open(filename + ".txt", "w") as f_new_out:
      for line in f_in:
        nums = line.split(' ')

        f_new_out.write(nums[0])
        f_new_out.write(" ")
        f_new_out.write(nums[1])
        f_new_out.write(" ")
        f_new_out.write(nums[2])

        f_new_out.write(" ")
        f_new_out.write(str(int(nums[3]) - threshold_1))
        f_new_out.write(" ")
        f_new_out.write(str(int(nums[4]) - threshold_2))
        f_new_out.write(" ")
        f_new_out.write(str(int(nums[5]) - threshold_3))
        f_new_out.write(" ")
        f_new_out.write(str(int(nums[6]) - threshold_4))
        f_new_out.write(" ")
        f_new_out.write(str(int(nums[7]) - threshold_5))
        f_new_out.write("\n")

      f_new_out.write(str(time.time() - start_time))

    f_in.close()
    os.system("del " + filename + "_raw.txt")
    print("Closing and exiting the program")

  except KeyboardInterrupt:
    SerialPort.close()
    sys.exit(0)

sys.exit(0)