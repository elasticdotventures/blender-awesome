# Blender MCP Integration Guide

This document explains how the Blender Awesome project integrates with the ahujasid/blender-mcp fork.

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  Blender Awesome Project (Main)                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Dev Container (blender-dev)                           │  │
│  │                                                         │  │
│  │  ┌─────────────────┐    ┌──────────────────┐          │  │
│  │  │  Blender 4.2    │    │  Web Dashboard   │          │  │
│  │  │  + MCP Addon    │◄───┤  (FastAPI)       │          │  │
│  │  └────────┬────────┘    └──────────────────┘          │  │
│  │           │ :9876                                      │  │
│  │           │                                            │  │
│  │  ┌────────▼────────┐    ┌──────────────────┐          │  │
│  │  │  Jupyter Lab    │    │  RL Training     │          │  │
│  │  │  :8888          │    │  (Stable-B3)     │          │  │
│  │  └─────────────────┘    └──────────────────┘          │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                           ▲
                           │ TCP :9876
                           │
┌──────────────────────────┼────────────────────────────────────┐
│  blender-mcp (Forked Submodule)                               │
│  ┌────────────────────────▼──────────────────────────────┐    │
│  │  MCP Server Container                                 │    │
│  │  ┌─────────────────────────────────────────────────┐  │    │
│  │  │  FastMCP Server                                 │  │    │
│  │  │  - execute_blender_code()                       │  │    │
│  │  │  - get_scene_info()                             │  │    │
│  │  │  - get_viewport_screenshot()                    │  │    │
│  │  │  - download_polyhaven_asset()                   │  │    │
│  │  │  - search_sketchfab_models()                    │  │    │
│  │  │  - generate_hyper3d_model_via_text()            │  │    │
│  │  └─────────────────────────────────────────────────┘  │    │
│  └───────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
                           ▲
                           │ stdio (MCP Protocol)
                           │
                    ┌──────┴───────┐
                    │  Claude AI   │
                    │  Desktop     │
                    └──────────────┘
```

## Components

### 1. Blender MCP Addon (`blender-mcp/addon.py`)

**Location**: Installed to `~/.config/blender/4.2/scripts/addons/blender_mcp_addon.py`

**Function**: Creates a TCP socket server (port 9876) inside Blender that:
- Listens for JSON commands
- Executes Blender operations in main thread (thread-safe via `bpy.app.timers.register()`)
- Returns results as JSON responses

**Commands Supported**:
- `get_scene_info` - Scene metadata
- `get_object_info` - Object details
- `execute_code` - Run Python in Blender
- `get_viewport_screenshot` - Capture viewport
- `download_polyhaven_asset` - Import PolyHaven assets
- `search_sketchfab_models` - Search Sketchfab
- `download_sketchfab_model` - Import Sketchfab models
- `create_rodin_job` - Generate with Hyper3D
- `poll_rodin_job_status` - Check generation status
- `import_generated_asset` - Import generated models

### 2. MCP Server (`blender-mcp/src/blender_mcp/server.py`)

**Location**: Python package installed via `uv pip install -e blender-mcp`

**Function**: Implements the Model Context Protocol using FastMCP:
- Exposes Blender operations as MCP tools (via `@mcp.tool()` decorators)
- Manages persistent TCP connection to Blender addon
- Handles chunked responses and error recovery
- Communicates with Claude via stdin/stdout (MCP protocol)

**MCP Tools Available to Claude**:
- `execute_blender_code(code: str)` - Execute arbitrary Python
- `get_scene_info()` - Get scene details
- `get_object_info(object_name: str)` - Get object info
- `get_viewport_screenshot(max_size: int)` - Capture screenshot
- `search_polyhaven_assets(asset_type, categories)` - Search assets
- `download_polyhaven_asset(asset_id, asset_type, resolution)` - Import assets
- `set_texture(object_name, texture_id)` - Apply textures
- `search_sketchfab_models(query, categories, count)` - Search models
- `download_sketchfab_model(uid)` - Import models
- `generate_hyper3d_model_via_text(prompt)` - Generate 3D from text
- `generate_hyper3d_model_via_images(paths)` - Generate from images
- And more...

### 3. Web Dashboard (`scripts/dashboard.py`)

**Location**: Main project, runs on port 3000

**Function**: Web UI for managing services
- Service status monitoring
- Project/model listing
- Git operations
- Blender console (communicates with MCP addon via TCP)

## Installation Flow

### During Container Build (`.devcontainer/setup.sh`)

```bash
# 1. Copy addon to Blender's addon directory
cp /workspace/blender-mcp/addon.py \
   ~/.config/blender/4.2/scripts/addons/blender_mcp_addon.py

# 2. Install MCP server as Python package
cd /workspace/blender-mcp
uv pip install -e .

# 3. Configure Claude Desktop
cat > ~/.config/claude-desktop/claude_desktop_config.json << EOF
{
  "mcpServers": {
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
```

### During Container Start (`.devcontainer/start-services.sh`)

```bash
# Start Blender in background with addon enabled
blender --background \
  --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon')" &
```

## Communication Flow

### Claude → Blender Execution

```
1. Claude Desktop sends MCP request via stdio
   ↓
2. MCP Server (blender-mcp) receives tool call
   ↓
3. MCP Server sends TCP command to localhost:9876
   ↓
4. Blender Addon receives JSON command
   ↓
5. Addon schedules execution in main thread (bpy.app.timers.register)
   ↓
6. Blender executes Python code
   ↓
7. Addon sends JSON response back via TCP
   ↓
8. MCP Server receives response
   ↓
9. MCP Server returns result to Claude via stdio
```

### Dashboard → Blender Execution

```
1. User enters code in dashboard
   ↓
2. Dashboard POSTs to /api/blender/execute
   ↓
3. Dashboard sends TCP to localhost:9876
   ↓
4. (Same flow as above from step 4)
```

## Docker Deployment

### Building the MCP Server Image

```bash
cd blender-mcp
docker build -t ghcr.io/elasticdotventures/blender-mcp:latest .
```

### Running with Docker Compose

```bash
# Start with MCP profile
docker-compose --profile mcp up
```

The `docker-compose.yml` includes:

```yaml
services:
  blender-mcp:
    build:
      context: ../blender-mcp
      dockerfile: Dockerfile
    environment:
      - BLENDER_HOST=blender-dev
      - BLENDER_PORT=9876
    depends_on:
      - blender-dev
```

### CI/CD

GitHub Actions workflow (`.github/workflows/docker-build.yml`) automatically:
- Builds multi-arch images (amd64, arm64)
- Pushes to `ghcr.io/elasticdotventures/blender-mcp`
- Tags: `latest`, `main`, `v*` (semver)

## Extension Points for Robotics

### Adding Custom MCP Tools

Edit `blender-mcp/src/blender_mcp/server.py`:

```python
@mcp.tool()
def export_urdf(ctx: Context, object_name: str, filepath: str) -> str:
    """Export Blender object to URDF format using Phobos"""
    try:
        blender = get_blender_connection()
        result = blender.send_command("export_urdf", {
            "object_name": object_name,
            "filepath": filepath
        })
        return f"URDF exported to {filepath}"
    except Exception as e:
        return f"Error exporting URDF: {str(e)}"
```

### Adding Custom Blender Commands

Edit `blender-mcp/addon.py`:

```python
# In the command handlers section
elif command_type == "export_urdf":
    def export_urdf_handler():
        import bpy
        obj = bpy.data.objects.get(params['object_name'])
        # Use Phobos addon
        bpy.ops.phobos.export_urdf(filepath=params['filepath'])
        send_response({"status": "success", "result": {"exported": True}})

    bpy.app.timers.register(export_urdf_handler, first_interval=0)
```

## Workflow Examples

### Example 1: Generate Robot Design with Claude

```
User: "Create a simple 2-wheeled robot in Blender"

Claude uses MCP tools:
1. generate_hyper3d_model_via_text("simple wheeled robot chassis")
2. poll_rodin_job_status(subscription_key)
3. import_generated_asset(name="robot_chassis", task_uuid)
4. execute_blender_code("bpy.ops.mesh.primitive_cylinder_add(...)")  # wheels
5. get_viewport_screenshot() → Shows user the result
```

### Example 2: Import and Texture Environment

```
User: "Set up a workshop environment with a metal floor"

Claude uses MCP tools:
1. search_polyhaven_assets(asset_type="textures", categories="metal")
2. download_polyhaven_asset(asset_id="metal_plate_001", asset_type="textures")
3. execute_blender_code("bpy.ops.mesh.primitive_plane_add(size=10)")
4. set_texture(object_name="Plane", texture_id="metal_plate_001")
5. search_polyhaven_assets(asset_type="hdris", categories="indoor")
6. download_polyhaven_asset(asset_id="workshop_01", asset_type="hdris")
```

### Example 3: Export for Physics Simulation

```
User: "Export this robot to URDF for MuJoCo"

Claude uses MCP tools:
1. get_scene_info() → Lists all objects
2. export_urdf(object_name="robot", filepath="/workspace/exports/robot.urdf")
3. # User can then load URDF in Gymnasium/MuJoCo
```

## Benefits of This Integration

### ✅ What We Gained

1. **Production-ready MCP implementation**
   - Proper FastMCP SDK usage
   - Thread-safe Blender execution
   - Robust error handling
   - Asset library integrations (PolyHaven, Sketchfab, Hyper3D)

2. **Maintained upstream**
   - Bug fixes from ahujasid
   - New features automatically available
   - Community contributions

3. **Docker packaging**
   - Easy deployment
   - Multi-arch support (amd64, arm64)
   - CI/CD automation

### ✨ What We Added

1. **Robotics workflow integration**
   - URDF export capability (TODO)
   - MuJoCo/Gymnasium integration (TODO)
   - RL training triggers (TODO)

2. **Web dashboard**
   - Visual service management
   - Direct Blender console
   - Git operations

3. **Development container**
   - Complete Python/Node/Rust environment
   - Pre-configured Jupyter Lab
   - Blender 4.2 LTS included

## Development Workflow

### Making Changes to MCP Server

```bash
# 1. Edit files in blender-mcp/
vim blender-mcp/src/blender_mcp/server.py

# 2. Rebuild container
docker-compose up --build blender-mcp

# 3. Test changes
# Claude Desktop will automatically reconnect
```

### Contributing Upstream

```bash
cd blender-mcp

# 1. Create feature branch
git checkout -b feature/urdf-export

# 2. Make changes

# 3. Commit
git commit -m "feat: Add URDF export tool"

# 4. Push to fork
git push origin feature/urdf-export

# 5. Create PR to ahujasid/blender-mcp
gh pr create --repo ahujasid/blender-mcp
```

## Troubleshooting

### MCP Server Can't Connect to Blender

**Check addon is running**:
```bash
docker exec -it blender-awesome-blender-dev-1 \
  blender --background --python-expr \
  "import bpy; print(bpy.ops.preferences.addon_enable(module='blender_mcp_addon'))"
```

**Check port is listening**:
```bash
docker exec -it blender-awesome-blender-dev-1 netstat -tlnp | grep 9876
```

### Claude Can't See MCP Tools

**Check MCP server is running**:
```bash
uvx blender-mcp  # Should start without errors
```

**Verify Claude Desktop config**:
```bash
cat ~/.config/claude-desktop/claude_desktop_config.json
```

**Check Claude Desktop logs**:
- macOS: `~/Library/Logs/Claude/`
- Windows: `%APPDATA%\Claude\logs\`
- Linux: `~/.config/Claude/logs/`

## Future Enhancements

### Planned MCP Tools

- [ ] `export_urdf(object_name, filepath)` - Export to URDF
- [ ] `create_mujoco_scene()` - Convert scene to MuJoCo XML
- [ ] `train_robot_policy(urdf_path, task)` - Trigger RL training
- [ ] `load_urdf(filepath)` - Import URDF into Blender
- [ ] `setup_physics_joints()` - Configure robot joints
- [ ] `run_simulation(steps)` - Run physics simulation
- [ ] `export_stl_batch()` - Batch export for 3D printing

### Planned Dashboard Features

- [ ] Live Blender viewport preview
- [ ] Training metrics visualization
- [ ] URDF validation
- [ ] Robot joint testing UI
- [ ] Simulation playback

## References

- Original MCP Server: https://github.com/ahujasid/blender-mcp
- Our Fork: https://github.com/elasticdotventures/blender-mcp
- Model Context Protocol: https://modelcontextprotocol.io
- Blender Python API: https://docs.blender.org/api/current/
- FastMCP SDK: https://github.com/jlowin/fastmcp
