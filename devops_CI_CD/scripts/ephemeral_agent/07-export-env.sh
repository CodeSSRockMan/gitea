#!/bin/bash
set -e

# 07-export-env.sh — Export agent info for downstream steps

# 1) Load config and state
source env.sh
source "$STATE_FILE"

# 2) Write out the essential variables
echo "AGENT_ID=$AGENT_INSTANCE_ID" > ephem_env.txt
echo "AGENT_IP=$AGENT_IP"        >> ephem_env.txt
echo "TOOL_VERSIONS=$TOOL_VERSIONS" >> ephem_env.txt

echo "[INFO] Exported environment to ephem_env.txt"
