#!/bin/bash

echo "🚀 Starting Blender Awesome services..."

# Start Blender in headless mode with MCP server
echo "🎨 Starting Blender MCP server..."
blender --background --python /workspace/scripts/start_blender_mcp.py &
BLENDER_PID=$!

# Wait a moment for Blender to start
sleep 5

# Start Jupyter Lab for dashboard
echo "📊 Starting Jupyter Lab dashboard..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &
JUPYTER_PID=$!

# Start dashboard web app
echo "🖥️ Starting web dashboard..."
python /workspace/scripts/dashboard.py &
DASHBOARD_PID=$!

# Save PIDs for cleanup
echo "$BLENDER_PID $JUPYTER_PID $DASHBOARD_PID" > /tmp/blender-awesome-pids

echo "✅ Services started!"
echo "📊 Dashboard: http://localhost:3000"
echo "📓 Jupyter: http://localhost:8888"
echo "🎨 Blender MCP: localhost:9876"

# Keep container running
wait