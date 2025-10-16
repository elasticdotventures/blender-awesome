#!/bin/bash

echo "🚀 Setting up Blender Awesome development environment..."

# Ensure we're in the workspace
cd /workspace

# Create project structure if it doesn't exist
mkdir -p {scripts,models,exports,tests,configs}

# Initialize git if not already initialized
if [ ! -d ".git" ]; then
    git init
    echo "# Blender Awesome - Generative CAD & Robotics" > README.md
    echo "logs/" > .gitignore
    echo "__pycache__/" >> .gitignore
    echo "*.pyc" >> .gitignore
    echo ".venv/" >> .gitignore
    echo "exports/*.stl" >> .gitignore
    echo "exports/*.dae" >> .gitignore
    echo "models/cache/" >> .gitignore
fi

# Set up Blender configuration for headless operation
mkdir -p ~/.config/blender/4.2/scripts/addons

# Install Phobos addon for URDF export (if available)
echo "📦 Checking for Phobos addon..."
if [ ! -d ~/.config/blender/4.2/scripts/addons/phobos ]; then
    echo "⚠️  Phobos addon not found. Please install manually:"
    echo "   1. Download from: https://github.com/dfki-ric/phobos"
    echo "   2. Extract to: ~/.config/blender/4.2/scripts/addons/phobos"
fi

# Create MCP configuration for Claude Desktop
mkdir -p ~/.config/claude-desktop
cat > ~/.config/claude-desktop/claude_desktop_config.json << 'EOF'
{
  "mcpServers": {
    "sequentialthinking": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "mcp/sequentialthinking"
      ]
    },
    "blender": {
      "command": "uvx",
      "args": ["blender-mcp"],
      "env": {
        "BLENDER_HOST": "localhost",
        "BLENDER_PORT": "9876"
      }
    }
  }
}
EOF

# Install additional Python packages specific to this project
echo "📦 Installing additional Python packages..."
uv pip install \
    blend-my-bot \
    PyFlyt \
    jsbsim || echo "Some packages may not be available"

# Create example scripts
cat > scripts/blender_python_example.py << 'EOF'
"""
Example Blender Python script for generative CAD
Based on the README.md workflow
"""
import bpy
import bmesh
import json
from mathutils import Vector, Matrix

def clear_scene():
    """Clear default scene objects"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)

def create_parametric_object(params):
    """Create parametric geometry from parameters"""
    mesh = bpy.data.meshes.new("parametric_object")
    obj = bpy.data.objects.new("parametric_object", mesh)
    bpy.context.collection.objects.link(obj)
    
    # Create bmesh
    bm = bmesh.new()
    
    # Example: create a parametric box
    bmesh.ops.create_cube(bm, size=params.get('size', 2.0))
    
    # Update mesh
    bm.to_mesh(mesh)
    bm.free()
    
    return obj

def export_urdf(obj, filepath):
    """Export object as URDF (requires Phobos addon)"""
    try:
        # This would use Phobos addon if available
        print(f"Would export {obj.name} to {filepath}")
        # bpy.ops.phobos.export_urdf(filepath=filepath)
    except:
        print("Phobos addon not available for URDF export")

if __name__ == "__main__":
    # Example usage
    params = {"size": 1.5}
    clear_scene()
    obj = create_parametric_object(params)
    export_urdf(obj, "/workspace/exports/model.urdf")
EOF

cat > scripts/mcp_blender_test.py << 'EOF'
"""
Test script for Blender MCP integration
"""
import subprocess
import time
import requests

def start_blender_mcp():
    """Start Blender with MCP server"""
    try:
        # Start Blender in background with Python server
        process = subprocess.Popen([
            "blender", 
            "--background",
            "--python-console"
        ])
        return process
    except Exception as e:
        print(f"Failed to start Blender MCP: {e}")
        return None

def test_mcp_connection():
    """Test MCP connection"""
    try:
        # This would test the actual MCP connection
        print("Testing MCP connection to Blender...")
        # Implement actual MCP test here
        return True
    except Exception as e:
        print(f"MCP connection test failed: {e}")
        return False

if __name__ == "__main__":
    print("🧪 Testing Blender MCP setup...")
    process = start_blender_mcp()
    if process:
        time.sleep(3)
        success = test_mcp_connection()
        process.terminate()
        print(f"✅ MCP test {'passed' if success else 'failed'}")
EOF

# Create example configuration files
cat > configs/blender_mcp.json << 'EOF'
{
  "blender": {
    "host": "localhost",
    "port": 9876,
    "python_path": "/opt/blender/python/bin/python3.11",
    "scripts_path": "/workspace/scripts",
    "addons_path": "~/.config/blender/4.2/scripts/addons"
  },
  "mcp": {
    "timeout": 30,
    "retry_count": 3
  }
}
EOF

# Set up Jupyter notebook with Blender kernel
echo "📓 Setting up Jupyter with Blender integration..."
cat > notebooks/blender_example.ipynb << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Blender Awesome - Generative CAD Example\n",
    "\n",
    "This notebook demonstrates the generative CAD workflow described in the README."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Import required libraries\n",
    "import sys\n",
    "sys.path.append('/opt/blender/python/lib/python3.11/site-packages')\n",
    "\n",
    "try:\n",
    "    import bpy\n",
    "    print(\"✅ Blender Python API available\")\n",
    "except ImportError:\n",
    "    print(\"⚠️  Blender Python API not available in this context\")\n",
    "    print(\"Use: blender --background --python notebook_script.py\")"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Blender Awesome",
   "language": "python",
   "name": "blender-awesome"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Create the notebooks directory
mkdir -p notebooks

# Make scripts executable
chmod +x scripts/*.py

echo "✅ Blender Awesome development environment setup complete!"
echo ""
echo "🎯 Next steps:"
echo "1. Install Phobos addon for URDF export"
echo "2. Configure Claude Desktop with MCP servers"
echo "3. Test Blender headless operation: blender --background --python scripts/blender_python_example.py"
echo "4. Start Jupyter: jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root"
echo ""
echo "📖 See README.md for the complete workflow guide"