#!/bin/bash
set -e

# Load environment and previous state
source env.sh

[[ -f "$STATE_FILE" ]] || { echo "[ERROR] STATE_FILE not found: $STATE_FILE"; exit 1; }

source "$STATE_FILE"

echo "[INFO] Loaded state:"
grep -v 'PASSWORD' "$STATE_FILE" | while read -r line; do
  echo "  $line"
done

# 2) Write out the essential variables
echo "AGENT_ID=$AGENT_INSTANCE_ID" > ephem_env.txt
echo "AGENT_IP=$AGENT_IP"        >> ephem_env.txt
echo "TOOL_VERSIONS=$TOOL_VERSIONS" >> ephem_env.txt

echo "[INFO] Exported environment to ephem_env.txt"
