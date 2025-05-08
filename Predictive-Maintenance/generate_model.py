#!/usr/bin/env python3
"""
train_autoencoder.py

• Reads telemetry.csv (must contain exactly six sensor columns plus
  any number of other columns, e.g. device_id, timestamp)
• Builds and trains a 6→3→6 autoencoder on just the six sensor features
• Writes /models/autoencoder_model.h5
"""

import os
import numpy as np
import pandas as pd
from tensorflow.keras import layers, models

# ── CONFIG ────────────────────────────────────────────────────────────────
CSV_PATH   = os.getenv("DATA_PATH",  "/home/henok/DREAM_1.3/Predictive-Maintenance/models/telemetry.csv")
MODEL_OUT  = os.getenv("MODEL_OUT",  "/home/henok/DREAM_1.3/Predictive-Maintenance/models/autoencoder_model.h5")
EPOCHS     = int(os.getenv("EPOCHS",      "50"))
BATCH_SIZE = int(os.getenv("BATCH_SIZE",  "64"))

# ── 1) load your synthetic telemetry ────────────────────────────────────────
df = pd.read_csv(CSV_PATH)
print(f"Loaded {len(df)} rows, columns: {list(df.columns)}")

# ── 2) Identify & extract exactly six sensor columns ───────────────────────
#    We drop any non-numeric or metadata columns automatically.
#    If you know your sensor columns are named r1…r6, you can hard-code that instead.
numeric = df.select_dtypes(include=[np.number])
# if you've got a timestamp in numeric, drop it explicitly:
for c in ["timestamp", "time", "ts"]:
    if c in numeric.columns:
        numeric = numeric.drop(columns=[c])

# now numeric should be exactly your six normalized features
if numeric.shape[1] != 6:
    raise ValueError(f"Expected 6 sensor features, found {numeric.shape[1]}: {list(numeric.columns)}")

X = numeric.values.astype("float32")
print("Using sensor columns:", list(numeric.columns))

# ── 3) re-scale (in case your generator didn’t pre-normalize exactly to [0,1]) ─
mins = X.min(axis=0)
maxs = X.max(axis=0)
X_norm = (X - mins) / (maxs - mins + 1e-8)

# ── 4) build the autoencoder ───────────────────────────────────────────────
input_dim    = X_norm.shape[1]   # should be 6
encoding_dim = 3

inp     = layers.Input(shape=(input_dim,))
encoded = layers.Dense(encoding_dim, activation="relu")(inp)
decoded = layers.Dense(input_dim,  activation="sigmoid")(encoded)

autoencoder = models.Model(inp, decoded)
autoencoder.compile(optimizer="adam", loss="mse")
autoencoder.summary()

# ── 5) train ────────────────────────────────────────────────────────────────
autoencoder.fit(
    X_norm, X_norm,
    epochs=EPOCHS,
    batch_size=BATCH_SIZE,
    shuffle=True,
    validation_split=0.1,
    verbose=2
)

# ── 6) write out the model ──────────────────────────────────────────────────
os.makedirs(os.path.dirname(MODEL_OUT) or ".", exist_ok=True)
autoencoder.save(MODEL_OUT)
print(f"✔️  Trained and saved autoencoder to {MODEL_OUT}")