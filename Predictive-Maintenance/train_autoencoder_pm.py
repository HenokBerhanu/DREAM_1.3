#!/usr/bin/env python3
"""
Train and save an Autoencoder for Predictive Maintenance.
Assumes a CSV of “normal” telemetry with one row per sample and 6 sensor columns.
"""

import os
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.layers import Input, Dense
from tensorflow.keras.models import Model
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint

# --- Configurable paths & parameters ---
DATA_PATH       = os.getenv("DATA_PATH", "/mnt/data/telemetry.csv")
MODEL_OUT       = os.getenv("MODEL_OUT", "models/autoencoder_pm.h5")
ENCODING_DIM    = int(os.getenv("ENCODING_DIM", "3"))     # bottleneck size
BATCH_SIZE      = int(os.getenv("BATCH_SIZE", "32"))
EPOCHS          = int(os.getenv("EPOCHS", "100"))
VALIDATION_SPLIT= float(os.getenv("VAL_SPLIT", "0.2"))
PATIENCE        = int(os.getenv("PATIENCE", "10"))

def load_data(path):
    # expects columns: sensor_1, sensor_2, ..., sensor_6 (or adjust accordingly)
    df = pd.read_csv(path)
    X = df.filter(regex="sensor_").values
    # normalize to [0,1]
    X = (X - X.min(axis=0)) / (X.max(axis=0) - X.min(axis=0) + 1e-8)
    return X

def build_autoencoder(input_dim, encoding_dim):
    inp = Input(shape=(input_dim,), name="encoder_input")
    # encoder
    x = Dense(encoding_dim * 2, activation="relu")(inp)
    bottleneck = Dense(encoding_dim, activation="relu", name="bottleneck")(x)
    # decoder
    x = Dense(encoding_dim * 2, activation="relu")(bottleneck)
    out = Dense(input_dim, activation="sigmoid", name="decoder_output")(x)
    model = Model(inputs=inp, outputs=out, name="autoencoder")
    model.compile(optimizer="adam", loss="mse")
    return model

def main():
    # 1) load data
    X = load_data(DATA_PATH)
    input_dim = X.shape[1]

    # 2) build model
    ae = build_autoencoder(input_dim, ENCODING_DIM)
    ae.summary()

    # 3) callbacks: early stop + best‐model checkpointing
    os.makedirs(os.path.dirname(MODEL_OUT), exist_ok=True)
    callbacks = [
        EarlyStopping(monitor="val_loss", patience=PATIENCE, restore_best_weights=True),
        ModelCheckpoint(MODEL_OUT, save_best_only=True, monitor="val_loss")
    ]

    # 4) train
    ae.fit(
        X, X,
        batch_size=BATCH_SIZE,
        epochs=EPOCHS,
        validation_split=VALIDATION_SPLIT,
        callbacks=callbacks,
        verbose=2
    )

    # 5) final save (redundant if checkpoint did it)
    ae.save(MODEL_OUT)
    print(f"Saved trained model to {MODEL_OUT}")

if __name__ == "__main__":
    main()
