from flask import Flask, request, jsonify
import argparse
from nginx_utils import update_nginx_conf, start_nginx

app = Flask(__name__)

current_config = {
    "primary": "127.0.0.1",
    "backup": "127.0.0.2"
}

@app.route("/update", methods=["POST"])
def update_ips():
    data = request.get_json()
    if "primary" not in data or "backup" not in data:
        return jsonify({"error": "Missing 'primary' or 'backup'"}), 400

    current_config["primary"] = data["primary"]
    current_config["backup"] = data["backup"]

    update_nginx_conf(data["primary"], data["backup"])

    return jsonify({"message": "Configuration updated"}), 200

@app.route("/current", methods=["GET"])
def get_current():
    return jsonify(current_config), 200

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", type=str, default="0.0.0.0")
    parser.add_argument("--port", type=int, default=5000)
    args = parser.parse_args()

    update_nginx_conf(current_config["primary"], current_config["backup"])
    start_nginx()

    app.run(host=args.host, port=args.port)
