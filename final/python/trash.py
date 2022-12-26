with open("trash.txt", "w") as file:
  # for i in range (0,500,1):
  #   file.write(f"\tdict_word_length_w[{i}] =")
  #   for j in range(0,104,4):
  #     if (j == 0):
  #       file.write(f" (count_dict[{i}][{j}:{j + 3}] != 4'b0);\n")
  #     if (j == 100):
  #       file.write(f"\t\t\t\t\t\t\t(count_dict[{i}][{j}:{j + 3}] != 4'b0);\n")
  #     else:
  #       file.write(f"\t\t\t\t\t\t\t(count_dict[{i}][{j}:{j + 3}] != 4'b0) +\n")

  file.write(f"word_count_w =")
  for i in range(0, 26, 1):
    for j in range(0, 120, 8):
      file.write(f"{pow(16, i)} * (alphabet[{i}] == i_similarity_word[{j}:{j+7}]) +\n")
      
