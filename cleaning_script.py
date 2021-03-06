# -*- coding: utf-8 -*-
"""cleaning_script.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/1jjyNJxbhe-ofBzqhIuRZnpktPI59UM9S
"""

import pandas as pd
import numpy as np



path = "National IPM Database.xlsx"

df = pd.read_excel(path)
df[:5]

crops = df.groupby(['Crops'])['States'].apply(','.join).reset_index()
crops.to_excel('by crops.xlsx')

states = df.groupby(['States'])['Crops'].apply(','.join).reset_index()
states.to_excel('by state.xlsx')