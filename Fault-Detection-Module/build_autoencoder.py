#!/usr/bin/env python3
"""
Generate and save a simple autoencoder for your telemetry data.
"""

import numpy as np
from tensorflow.keras import layers, models

# 1) Generate synthetic “normal” telemetry data
n_samples = 10000
occupancy     = np.random.randint(0, 2,     size=(n_samples, 1))
heart_rate    = np.random.randint(60, 101,  size=(n_samples, 1))
flow_rate     = np.random.uniform(20.0, 100.0, size=(n_samples, 1))
resp_rate     = np.random.randint(12,  26,  size=(n_samples, 1))
tidal_volume  = np.random.uniform(300.0, 500.0, size=(n_samples, 1))
battery_level = np.random.randint(20,  101, size=(n_samples, 1))

data = np.hstack([occupancy, heart_rate, flow_rate,
                  resp_rate, tidal_volume, battery_level])

# 2) Scale each feature to [0,1]
mins = data.min(axis=0)
maxs = data.max(axis=0)
data = (data - mins) / (maxs - mins)

# 3) Build a tiny autoencoder
input_dim = data.shape[1]
encoding_dim = 3

input_layer = layers.Input(shape=(input_dim,))
encoded     = layers.Dense(encoding_dim, activation='relu')(input_layer)
decoded     = layers.Dense(input_dim,    activation='sigmoid')(encoded)
autoencoder = models.Model(input_layer, decoded)
autoencoder.compile(optimizer='adam', loss='mse')

# 4) Train
autoencoder.fit(data, data,
                epochs=20,
                batch_size=64,
                shuffle=True,
                verbose=2)

# 5) Save to HDF5
model_path = "autoencoder_model.h5"
autoencoder.save(model_path)
print(f"Autoencoder trained and saved to {model_path}")
