import math
word = input(">")
# word = "000000000000000000000000000000000000000000000000000000000000100000000011000100100000000100000101000100110000010100010010"
buffer = []
for i in range(0, 120, 8):
  # print(word[i:i + 8])
  num = 0
  for j in range(i, i + 8):
    num += pow(2, 7 - j + i) * int(word[j])
  if num != 0:
    buffer.append(num + 96)

buffer.reverse()

for c in buffer:
  print(chr(c), end = '')

print("")