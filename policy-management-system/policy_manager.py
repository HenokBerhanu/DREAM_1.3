from __future__ import annotations

import logging
import os
import time
from typing import Dict, List

import requests
from flask import Flask, jsonify, request
from werkzeug.exceptions import BadRequest, InternalServerError

#
# ------------------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------------------
SDN_URL = os.getenv("SDN_CONTROLLER_URL", "http://onos-service.micro-onos.svc.cluster.local:8181/onos/v1")
SDN_USER = os.getenv("SDN_CONTROLLER_USER", "onos")          # secret-backed
SDN_PASS = os.getenv("SDN_CONTROLLER_PASS", "rocks")         # secret-backed
MAX_RETRIES = int(os.getenv("ONOS_MAX_RETRIES", 3))
BACKOFF_SEC = float(os.getenv("ONOS_BACKOFF_SEC", 2.0))

#
# ------------------------------------------------------------------------------
# BOILERPLATE
# ------------------------------------------------------------------------------
app = Flask(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s",
)

session = requests.Session()
session.auth = (SDN_USER, SDN_PASS)
session.headers.update({"Content-Type": "application/json"})


def _forward_to_sdn(policy: Dict) -> Dict:
    """POST policy to ONOS with retry/back-off."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            url = f"{SDN_URL}/onos/v1/policies"           # example ONOS NBI
            resp = session.post(url, json=policy, timeout=5)
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # pylint: disable=broad-except
            logging.error("Attempt %s/%s – ONOS call failed: %s",
                          attempt, MAX_RETRIES, exc)
            if attempt == MAX_RETRIES:
                raise InternalServerError("SDN controller unavailable") from exc
            time.sleep(BACKOFF_SEC * attempt)


#
# ------------------------------------------------------------------------------
# ROUTES
# ------------------------------------------------------------------------------
POLICIES: List[Dict] = []   # in-memory store (replace with DB if needed)


@app.route("/policies", methods=["GET"])
def list_policies():
    return jsonify(POLICIES)


@app.route("/policies", methods=["POST"])
def create_policy():
    if not request.is_json:
        raise BadRequest("Expected application/json")
    body = request.get_json()
    if "policy" not in body:
        raise BadRequest("Missing 'policy' field")
    resp = _forward_to_sdn(body["policy"])
    POLICIES.append(body["policy"])
    return jsonify({"msg": "policy applied", "sdn": resp}), 201


@app.route("/policies/<int:idx>", methods=["DELETE"])
def delete_policy(idx: int):
    try:
        deleted = POLICIES.pop(idx)
    except IndexError as exc:
        raise BadRequest("No such policy index") from exc
    # tell SDN to delete it (left as exercise)
    return jsonify({"msg": "policy removed", "policy": deleted})


@app.route("/healthz")
def health():
    return "ok"


@app.route("/readyz")
def ready():
    # simple check – extend with SDN ping if desired
    return "ready"


if __name__ == "__main__":  # pragma: no cover
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5002)))
