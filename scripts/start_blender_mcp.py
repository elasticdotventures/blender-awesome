"""
Blender MCP Server Startup Script
Starts Blender with MCP server for AI agent integration
"""
import bpy
import sys
import os
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

# Add workspace to path
sys.path.append('/workspace')

class MCPHandler(BaseHTTPRequestHandler):
    """Simple MCP server for Blender integration"""

    def do_POST(self):
        """Handle MCP requests"""
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            request = json.loads(post_data.decode('utf-8'))

            # Process the request (simplified)
            response = {
                "jsonrpc": "2.0",
                "id": request.get("id"),
                "result": {
                    "status": "Blender MCP server running",
                    "blender_version": bpy.app.version_string,
                    "scene_objects": len(bpy.context.scene.objects)
                }
            }

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode())

        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

def start_mcp_server():
    """Start the MCP server"""
    try:
        server = HTTPServer(('localhost', 9876), MCPHandler)
        print("🎨 Blender MCP server started on port 9876")
        server.serve_forever()
    except Exception as e:
        print(f"Failed to start MCP server: {e}")

def setup_blender():
    """Setup Blender for headless operation"""
    # Clear default scene
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

    # Set up basic scene
    bpy.ops.object.light_add(type='SUN', location=(5, 5, 5))
    bpy.ops.object.camera_add(location=(10, -10, 10))
    bpy.context.scene.camera = bpy.context.object

    print("🎨 Blender scene initialized")

if __name__ == "__main__":
    print("🚀 Starting Blender MCP integration...")

    # Setup Blender
    setup_blender()

    # Start MCP server in background thread
    mcp_thread = threading.Thread(target=start_mcp_server, daemon=True)
    mcp_thread.start()

    print("✅ Blender MCP ready!")
    print("🎨 Blender version:", bpy.app.version_string)
    print("📊 Scene objects:", len(bpy.context.scene.objects))

    # Keep Blender running
    while True:
        time.sleep(1)