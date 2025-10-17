# Blender Awesome - Justfile
# Task runner for Blender plugin installation and common operations
# Install just: https://github.com/casey/just

# Default recipe - show help
default:
    @just --list

# Variables
blender := env_var_or_default('BLENDER_PATH', 'blender')
blender_version := "4.2"
addon_dir := env_var_or_default('HOME', env_var('USERPROFILE')) / ".config/blender" / blender_version / "scripts/addons"
workspace := justfile_directory()

# Install Blender MCP addon
install-mcp-addon:
    @echo "📦 Installing Blender MCP addon..."
    mkdir -p {{addon_dir}}
    cp {{workspace}}/blender-mcp/addon.py {{addon_dir}}/blender_mcp_addon.py
    @echo "✅ MCP addon copied to {{addon_dir}}"

# Enable Blender MCP addon
enable-mcp-addon:
    @echo "🔌 Enabling Blender MCP addon..."
    {{blender}} --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon'); bpy.ops.wm.save_userpref()"
    @echo "✅ MCP addon enabled"

# Install and enable MCP addon (combined)
setup-mcp: install-mcp-addon enable-mcp-addon
    @echo "✅ Blender MCP addon fully installed and enabled"

# Install Phobos addon for URDF export
install-phobos:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Installing Phobos addon..."
    PHOBOS_DIR="{{addon_dir}}/phobos"
    if [ -d "$PHOBOS_DIR" ]; then
        echo "⚠️  Phobos already installed at $PHOBOS_DIR"
    else
        echo "Cloning Phobos from GitHub..."
        git clone https://github.com/dfki-ric/phobos.git "$PHOBOS_DIR"
        echo "✅ Phobos cloned to $PHOBOS_DIR"
    fi

# Enable Phobos addon
enable-phobos:
    @echo "🔌 Enabling Phobos addon..."
    {{blender}} --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='phobos'); bpy.ops.wm.save_userpref()"
    @echo "✅ Phobos addon enabled"

# Setup Phobos (install + enable)
setup-phobos: install-phobos enable-phobos
    @echo "✅ Phobos addon fully installed and enabled"

# List installed addons
list-addons:
    @echo "📋 Installed Blender addons:"
    {{blender}} --background --python-expr "import addon_utils; print('\\n'.join([a.__name__ for a in addon_utils.modules(refresh=False)]))"

# List enabled addons
list-enabled:
    @echo "✅ Enabled Blender addons:"
    {{blender}} --background --python-expr "import addon_utils; print('\\n'.join([a[0] for a in addon_utils.modules(refresh=False) if addon_utils.check(a[0])[0]]))"

# Verify MCP addon is working
verify-mcp:
    @echo "🧪 Verifying Blender MCP addon..."
    {{blender}} --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon'); print('✅ MCP addon loaded successfully')"

# Test MCP connection
test-mcp:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧪 Testing MCP connection..."

    # Start Blender with MCP addon in background
    {{blender}} --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon')" &
    BLENDER_PID=$!

    # Wait for Blender to start
    sleep 5

    # Test connection (requires nc/netcat)
    if command -v nc &> /dev/null; then
        echo '{"type": "get_scene_info"}' | nc localhost 9876
    else
        echo "⚠️  netcat (nc) not found - cannot test connection"
    fi

    # Cleanup
    kill $BLENDER_PID 2>/dev/null || true
    echo "✅ Test complete"

# Build blender-mcp Docker image
build-mcp-docker:
    @echo "🐳 Building blender-mcp Docker image..."
    docker build -t blender-mcp:latest blender-mcp/
    @echo "✅ Docker image built: blender-mcp:latest"

# Build and tag for GHCR
build-mcp-docker-ghcr version:
    @echo "🐳 Building blender-mcp for GHCR..."
    docker build \
        -t ghcr.io/elasticdotventures/blender-mcp:{{version}} \
        -t ghcr.io/elasticdotventures/blender-mcp:latest \
        blender-mcp/
    @echo "✅ Docker image built with tags: {{version}}, latest"

# Push to GHCR
push-mcp-docker version:
    @echo "📤 Pushing to GHCR..."
    docker push ghcr.io/elasticdotventures/blender-mcp:{{version}}
    docker push ghcr.io/elasticdotventures/blender-mcp:latest
    @echo "✅ Pushed to GHCR"

# Run blender-mcp Docker container
run-mcp-docker:
    @echo "🚀 Running blender-mcp container..."
    docker run -i --rm \
        -e BLENDER_HOST=host.docker.internal \
        -e BLENDER_PORT=9876 \
        blender-mcp:latest

# Start all services with docker-compose
up:
    @echo "🚀 Starting all services..."
    cd {{workspace}}/.devcontainer && docker-compose up -d
    @echo "✅ Services started"

# Start services with MCP profile
up-mcp:
    @echo "🚀 Starting services with MCP..."
    cd {{workspace}}/.devcontainer && docker-compose --profile mcp up -d
    @echo "✅ Services started with MCP"

# Stop all services
down:
    @echo "🛑 Stopping all services..."
    cd {{workspace}}/.devcontainer && docker-compose down
    @echo "✅ Services stopped"

# View service logs
logs service="blender-dev":
    @echo "📋 Logs for {{service}}..."
    cd {{workspace}}/.devcontainer && docker-compose logs -f {{service}}

# Rebuild and restart services
rebuild:
    @echo "🔨 Rebuilding services..."
    cd {{workspace}}/.devcontainer && docker-compose up -d --build
    @echo "✅ Services rebuilt and restarted"

# Clean Docker resources
clean:
    @echo "🧹 Cleaning Docker resources..."
    cd {{workspace}}/.devcontainer && docker-compose down -v
    docker system prune -f
    @echo "✅ Cleaned"

# Install blender-mcp Python package
install-mcp-server:
    @echo "📦 Installing blender-mcp server..."
    cd {{workspace}}/blender-mcp && uv pip install -e .
    @echo "✅ blender-mcp server installed"

# Run blender-mcp server locally
run-mcp-server:
    @echo "🚀 Running blender-mcp server..."
    cd {{workspace}}/blender-mcp && python -m blender_mcp.server

# Create Claude Desktop config - sets up MCP server for Claude Desktop integration
setup-claude-config:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "⚙️  Creating Claude Desktop config..."
    CONFIG_DIR="${HOME}/.config/claude-desktop"
    CONFIG_FILE="${CONFIG_DIR}/claude_desktop_config.json"
    mkdir -p "$CONFIG_DIR"
    echo '{"mcpServers":{"blender":{"command":"uvx","args":["blender-mcp"],"env":{"BLENDER_HOST":"localhost","BLENDER_PORT":"9876"}}}}' > "$CONFIG_FILE"
    echo "✅ Claude Desktop config created at $CONFIG_FILE"

# Full setup - install everything
setup-all: install-mcp-addon enable-mcp-addon install-phobos enable-phobos install-mcp-server setup-claude-config
    @echo "✅ Complete setup finished!"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Start Blender: just start-blender"
    @echo "  2. Test MCP: just test-mcp"
    @echo "  3. Open Claude Desktop and use Blender tools"

# Start Blender with MCP addon
start-blender:
    @echo "🎨 Starting Blender with MCP addon..."
    {{blender}} --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon')"

# Start Blender headless with MCP
start-blender-headless:
    @echo "🎨 Starting Blender headless with MCP..."
    {{blender}} --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon'); import time; time.sleep(999999)"

# Run example Blender script
run-example script="blender_python_example.py":
    @echo "🐍 Running {{script}}..."
    {{blender}} --background --python {{workspace}}/scripts/{{script}}

# Export current scene to URDF (requires Phobos)
export-urdf output="exports/model.urdf":
    @echo "📤 Exporting to URDF..."
    {{blender}} --background --python-expr "import bpy; bpy.ops.phobos.export_urdf(filepath='{{workspace}}/{{output}}')"
    @echo "✅ Exported to {{output}}"

# Start Jupyter Lab
start-jupyter:
    @echo "📓 Starting Jupyter Lab..."
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser

# Start web dashboard
start-dashboard:
    @echo "🖥️  Starting web dashboard..."
    python {{workspace}}/scripts/dashboard.py

# Git: Check status
git-status:
    @git status --short

# Git: Commit all changes
git-commit message:
    @echo "💾 Committing changes..."
    git add .
    git commit -m "{{message}}"
    @echo "✅ Committed: {{message}}"

# Git: Push to remote
git-push:
    @echo "📤 Pushing to remote..."
    git push
    @echo "✅ Pushed"

# Git: Commit and push
git-save message: (git-commit message) git-push

# GitHub: Trigger workflow
gh-workflow workflow="docker-build.yml":
    @echo "🔄 Triggering GitHub workflow: {{workflow}}"
    cd {{workspace}}/blender-mcp && gh workflow run {{workflow}}
    @echo "✅ Workflow triggered"

# GitHub: Watch latest workflow run
gh-watch:
    @echo "👀 Watching workflow..."
    cd {{workspace}}/blender-mcp && gh run watch

# Check if tools are installed
check-deps:
    #!/usr/bin/env bash
    echo "🔍 Checking dependencies..."

    command -v blender >/dev/null 2>&1 && echo "✅ blender" || echo "❌ blender (install from blender.org)"
    command -v docker >/dev/null 2>&1 && echo "✅ docker" || echo "❌ docker"
    command -v docker-compose >/dev/null 2>&1 && echo "✅ docker-compose" || echo "❌ docker-compose"
    command -v uv >/dev/null 2>&1 && echo "✅ uv" || echo "❌ uv (install via: curl -LsSf https://astral.sh/uv/install.sh | sh)"
    command -v gh >/dev/null 2>&1 && echo "✅ gh" || echo "❌ gh (GitHub CLI)"
    command -v jupyter >/dev/null 2>&1 && echo "✅ jupyter" || echo "❌ jupyter"
    command -v python >/dev/null 2>&1 && echo "✅ python" || echo "❌ python"
    command -v git >/dev/null 2>&1 && echo "✅ git" || echo "❌ git"

    echo ""
    echo "Blender path: {{blender}}"
    echo "Addon dir: {{addon_dir}}"
    echo "Workspace: {{workspace}}"

# Show project info
info:
    @echo "📊 Blender Awesome - Project Info"
    @echo ""
    @echo "Workspace: {{workspace}}"
    @echo "Blender: {{blender}}"
    @echo "Addon directory: {{addon_dir}}"
    @echo ""
    @echo "Services:"
    @echo "  - Jupyter Lab: http://localhost:8888"
    @echo "  - Dashboard: http://localhost:3000"
    @echo "  - Blender MCP: localhost:9876"
    @echo ""
    @echo "Run 'just check-deps' to verify all dependencies"
