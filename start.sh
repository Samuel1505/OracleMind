#!/bin/bash

# Trap SIGINT to kill background processes on Ctrl+C
trap "kill 0" EXIT

echo "🚀 Starting OracleMind System..."

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "Error: Port $1 is already in use. Please free it and try again."
        exit 1
    fi
}

check_port 8000
check_port 3000

# 1. Start AI API
echo "[1/2] Starting AI Layer (FastAPI) on :8000..."
source ai/venv/bin/activate
# Run from root so python path works if needed, or set PYTHONPATH
export PYTHONPATH=$PYTHONPATH:$(pwd)
uvicorn ai.services.api:app --host 0.0.0.0 --port 8000 --log-level info &
AI_PID=$!

# 2. Start Oracle Node
echo "[2/2] Starting Oracle Service (Node.js) on :3000..."
# Using npx tsx to run directly
# We enter the directory so .env is loaded correctly
(cd oracle && npx tsx src/server.ts) &
ORACLE_PID=$!

echo "Waiting 5s for services to stabilize..."
sleep 5

echo "✅ System Operational!"
echo "---------------------------------------------------"
echo "AI API:       http://localhost:8000/docs"
echo "Oracle Node:  http://localhost:3000"
echo "---------------------------------------------------"
echo "To run the E2E Demo:"
echo "npx ts-node examples/e2e_demo.ts"
echo "---------------------------------------------------"
echo "Press Ctrl+C to stop all services."

# Wait for any process to exit
wait
