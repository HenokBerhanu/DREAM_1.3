from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

SDN_CONTROLLER_URL = "http://onos-controller:8181"

@app.route("/update-policy", methods=["POST"])
def update_policy():
    data = request.get_json()
    policy = data["policy"]
    
    response = requests.post(f"{SDN_CONTROLLER_URL}/update-flow", json=policy)
    return jsonify({"message": "Policy updated", "response": response.json()})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002)
