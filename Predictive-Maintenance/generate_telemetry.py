#!/usr/bin/env python3
import pandas as pd
import numpy as np
import random
import time
import os

# ── CONFIG ────────────────────────────────────────────────────────────────
OUT_CSV = os.getenv("OUT_CSV", "/telemetry.csv")
N_PER_TYPE = int(os.getenv("N_PER_TYPE", "500"))

# ── DEVICE SPECS ──────────────────────────────────────────────────────────
# Each generator returns a list of 6 normalized readings
device_specs = {
    "ventilator": {
        "ids": ["ventilator_01", "ventilator_02", "ventilator_03"],
        "gen": lambda: [
            random.randint(12, 25) / 25.0,       # respiratory_rate / max
            random.uniform(300, 500) / 500.0,    # tidal_volume / max
            0, 0, 0, 0
        ]
    },
    "ecg_monitor": {
        "ids": ["ecg_monitor_01", "ecg_monitor_02", "ecg_monitor_03"],
        "gen": lambda: [
            random.randint(60, 100) / 100.0,     # heart_rate / max
            0, 0, 0, 0, 0
        ]
    },
    "infusion_pump": {
        "ids": ["infusion_pump_01", "infusion_pump_02", "infusion_pump_03"],
        "gen": lambda: [
            random.uniform(20.0, 100.0) / 100.0, # flow_rate / max
            0, 0, 0, 0, 0
        ]
    },
    "wheelchair": {
        "ids": ["wheelchair_01", "wheelchair_02", "wheelchair_03"],
        "gen": lambda: [
            random.randint(20, 100) / 100.0,     # battery_level / max
            random.randint(100, 120) / 120.0,    # room / max
            random.randint(1, 5) / 5.0,          # floor / max
            0, 0, 0
        ]
    },
    "bed_sensor": {
        "ids": ["bed_sensor_01", "bed_sensor_02", "bed_sensor_03"],
        "gen": lambda: [
            random.choice([0, 1]),               # occupancy (0 or 1)
            0, 0, 0, 0, 0
        ]
    }
}

# ── GENERATE ROWS ─────────────────────────────────────────────────────────
rows = []
base_ts = int(time.time())
for spec in device_specs.values():
    for _ in range(N_PER_TYPE):
        device_id = random.choice(spec["ids"])
        ts = base_ts + random.randint(0, 3600)
        readings = spec["gen"]()
        row = {
            "timestamp": ts,
            "device_id": device_id,
        }
        # expand the six-element list into r1…r6
        for i, v in enumerate(readings, start=1):
            row[f"r{i}"] = v
        rows.append(row)

# ── SHUFFLE & SAVE ────────────────────────────────────────────────────────
df = pd.DataFrame(rows).sample(frac=1).reset_index(drop=True)
os.makedirs(os.path.dirname(OUT_CSV), exist_ok=True)
df.to_csv(OUT_CSV, index=False)
print(f"Synthetic telemetry with {len(df)} rows written to {OUT_CSV}")
print(df.head())
