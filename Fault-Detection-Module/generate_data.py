#!/usr/bin/env python3
"""
Generate synthetic “normal” telemetry for your 6-dim autoencoder.
Each row is one of your five devices, with the appropriate 2 real features
and zeros elsewhere.
"""

import numpy as np
import pandas as pd

# number of samples total
N = 10000

# proportions (you can adjust if some devices are more common)
probs = {
    "ventilator": 0.2,
    "ecg":        0.2,
    "infusion":   0.2,
    "bed":        0.2,
    "wheelchair": 0.2,
}

# cumulative for sampling
names, ps = zip(*probs.items())
cum_ps = np.cumsum(ps)

def sample_device():
    r = np.random.random()
    for name, cp in zip(names, cum_ps):
        if r < cp:
            return name

rows = []
for _ in range(N):
    dev = sample_device()
    # start with zeros
    rec = np.zeros(6, dtype=float)
    if dev == "ventilator":
        # respiratory_rate 12–25, tidal_volume 300–500
        rec[0] = np.random.randint(12, 26)
        rec[1] = np.random.uniform(300, 500)
    elif dev == "ecg":
        rec[0] = np.random.randint(60, 101)
    elif dev == "infusion":
        rec[0] = np.random.uniform(20.0, 100.0)
    elif dev == "bed":
        rec[0] = np.random.choice([0, 1])
    elif dev == "wheelchair":
        rec[0] = np.random.randint(20, 101)      # battery %
        rec[1] = np.random.randint(100, 121)     # room
        rec[2] = np.random.randint(1, 6)         # floor
    rows.append(rec)

data = np.stack(rows)

# scale each column independently to [0,1]
mins = data.min(axis=0)
maxs = data.max(axis=0)
scaled = (data - mins) / (maxs - mins + 1e-8)

# save out for training
df = pd.DataFrame(scaled, columns=[
    "f0","f1","f2","f3","f4","f5"
])
df.to_csv("telemetry.csv", index=False)
print("Wrote synthetic telemetry.csv with shape", df.shape)
