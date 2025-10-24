# Blender Awesome - Justfile
# Task runner for Blender plugin installation and common operations
# Install just: https://github.com/casey/just

# Default recipe - show help
default:
    @just --list

# Variables - Auto-detect system Blender
workspace := justfile_directory()

compose-stack := "docker compose -f \"" + workspace + "/blender-mcp/docker-compose.yml\" -p blender-mcp"

install:
    @target_dir="{{workspace}}/DeepSeek-OCR/models/deepseek-ai__DeepSeek-OCR"; \
    mkdir -p "${target_dir}"; \
    if [ ! -f "${target_dir}/config.json" ]; then \
        echo "📥 Downloading DeepSeek-OCR snapshot to ${target_dir}"; \
        uvx --from huggingface-hub huggingface-cli download deepseek-ai/DeepSeek-OCR \
            --local-dir "${target_dir}" \
            --local-dir-use-symlinks False; \
    fi; \
    python3 - "${target_dir}" -c 'import json, sys; from pathlib import Path; target = Path(sys.argv[1]); cfg_path = target / "config.json";\nif not cfg_path.exists():\n    print(f"❌ Missing config.json at {cfg_path}", file=sys.stderr); sys.exit(1)\ncfg = json.loads(cfg_path.read_text()); updated = False\nif cfg.get("model_type") != "deepseek_vl2":\n    cfg["model_type"] = "deepseek_vl2"; updated = True\ncfg.setdefault("architectures", ["DeepseekVLV2ForCausalLM"])\ndesired_auto_map = {\n    \"AutoConfig\": \"vllm.transformers_utils.configs.deepseek_vl2.DeepseekVLV2Config\",\n    \"AutoModel\": \"vllm.transformers_utils.configs.deepseek_vl2.DeepseekVLV2ForCausalLM\",\n    \"AutoModelForCausalLM\": \"vllm.transformers_utils.configs.deepseek_vl2.DeepseekVLV2ForCausalLM\",\n}\nauto_map = cfg.get(\"auto_map\", {})\nif auto_map != desired_auto_map:\n    auto_map.update(desired_auto_map)\n    cfg[\"auto_map\"] = auto_map\n    updated = True\nif updated:\n    cfg_path.write_text(json.dumps(cfg, indent=2))\n    print(f\"🛠️  Patched config metadata at {cfg_path}\")\nelse:\n    print(f\"✅ Config metadata already patched at {cfg_path}\")\n'
    bash {{workspace}}/blender-mcp/patch_deepseek_ocr.sh "{{workspace}}/DeepSeek-OCR/models/deepseek-ai__DeepSeek-OCR"
    echo ""
    echo "Next steps:"
    echo "  • export VLLM_MODEL_DIR=${target_dir}"

hf-download model dest="":
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="$HOME/.local/uv-tools/bin:$HOME/.local/share/uv/tools/bin:$PATH"
    MODEL="{{model}}"
    DEST="{{dest}}"
    if [ -z "$DEST" ]; then
        SAFE_NAME="${MODEL//\//__}"
        DEST="$HOME/.models/$SAFE_NAME"
    fi
    mkdir -p "$DEST"
    echo "📥 Downloading $MODEL to $DEST"
    huggingface-cli download "$MODEL" \
        --local-dir "$DEST" \
        --local-dir-use-symlinks False

vllm-up:
    direnv exec {{workspace}}/blender-mcp docker compose up -d vllm

vllm-logs:
    direnv exec {{workspace}}/blender-mcp docker compose logs -f vllm

# Ensure git submodules (e.g. blender-mcp) are initialized
update-submodules:
    git submodule update --init --recursive

# Detect Blender (uses scripts/detect_blender.sh)
[private]
detect:
    #!/usr/bin/env bash
    if [ ! -f "{{workspace}}/.blender.env" ]; then
        bash {{workspace}}/scripts/detect_blender.sh > /dev/null 2>&1 || echo "⚠️  Blender detection failed"
    fi

# Load Blender settings (auto-detected or defaults)
# Auto-detect WSL and use appropriate env file
blender := if path_exists(".blender.env.wsl") == "true" {`grep BLENDER_EXE .blender.env.wsl | cut -d= -f2`} else if path_exists(".blender.env") == "true" {`grep BLENDER_EXE .blender.env | cut -d= -f2`} else {"/mnt/c/Program Files/Blender Foundation/Blender 4.3/blender.exe"}
addon_dir := if path_exists(".blender.env.wsl") == "true" {`grep BLENDER_ADDON_DIR .blender.env.wsl | cut -d= -f2`} else if path_exists(".blender.env") == "true" {`grep BLENDER_ADDON_DIR .blender.env | cut -d= -f2`} else {"/mnt/c/Users/Brian/AppData/Roaming/Blender Foundation/Blender/4.3/scripts/addons"}

# Import b00t datum
mod b00t-blender '_b00t_/_b00t_/blender.🎨/justfile'

# Show detected Blender info
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
    @just detect
    @cat .blender.env 2>/dev/null || echo "Run 'just detect-blender' to scan for Blender"

# Manually run Blender detection
detect-blender:
    @bash {{workspace}}/scripts/detect_blender.sh

# Install Blender MCP addon to detected system Blender
install-mcp-addon:
    @echo "📦 Installing Blender MCP addon to system Blender..."
    @just detect
    mkdir -p "{{addon_dir}}"
    cp {{workspace}}/blender-mcp/addon.py "{{addon_dir}}/blender_mcp_addon.py"
    @echo "✅ MCP addon installed to {{addon_dir}}"

# Enable Blender MCP addon
enable-mcp-addon:
    @echo "🔌 Enabling Blender MCP addon..."
    "{{blender}}" --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon'); bpy.ops.wm.save_userpref()"
    @echo "✅ MCP addon enabled"

# Install Phobos addon for URDF export
install-phobos:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🤖 Installing Phobos addon..."
    ADDON_DIR="{{addon_dir}}"
    if [ -d "phobos" ]; then
        mkdir -p "$ADDON_DIR/phobos"
        rsync -a --delete --exclude=".git" --exclude=".github" phobos/ "$ADDON_DIR/phobos/"
        echo "✅ Phobos installed to $ADDON_DIR/phobos"
    else
        echo "📥 Cloning Phobos from GitHub..."
        git clone https://github.com/dfki-ric/phobos.git "$ADDON_DIR/phobos"
        echo "✅ Phobos cloned and installed"
    fi

# Enable Phobos addon
enable-phobos:
    @echo "🔌 Enabling Phobos addon..."
    "{{blender}}" --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='phobos'); bpy.ops.wm.save_userpref()"
    @echo "✅ Phobos addon enabled"

# Export current scene to URDF (requires Phobos)
export-urdf output="exports/model.urdf":
    @echo "📤 Exporting to URDF..."
    "{{blender}}" --background --python-expr "import bpy; bpy.ops.phobos.export_urdf(filepath='{{workspace}}/{{output}}')"
    @echo "✅ Exported to {{output}}"

# List installed addons
list-addons:
    @echo "📋 Installed Blender addons:"
    "{{blender}}" --background --python-expr "import addon_utils; [print(f'  {a.__name__}') for a in addon_utils.modules(refresh=False)]"

# List enabled addons
list-enabled:
    @echo "✅ Enabled Blender addons:"
    "{{blender}}" --background --python-expr "import addon_utils; [print(f'  ✅ {a[0]}') for a in addon_utils.modules(refresh=False) if addon_utils.check(a[0])[0]]"

# Verify MCP addon is working
verify-mcp:
    @echo "🧪 Verifying Blender MCP addon..."
    "{{blender}}" --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon'); print('✅ MCP addon loaded successfully')"

# Test MCP connection (TCP socket mode)
test-mcp:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🧪 Testing MCP connection..."
    "{{blender}}" --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon')" &
    BLENDER_PID=$!
    sleep 5
    if command -v nc &> /dev/null; then
        echo '{"type": "get_scene_info"}' | nc localhost 9876
    else
        echo "⚠️  netcat (nc) not found - cannot test connection"
    fi
    kill $BLENDER_PID 2>/dev/null || true
    echo "✅ Test complete"

# Test MCP stdio server (new architecture)
test-mcp-stdio:
    @echo "🧪 Testing Blender MCP stdio server..."
    python {{workspace}}/blender-mcp/test_stdio_simple.py

# ============================================================================
# Container Stack - GPU vLLM & MCP services
# ============================================================================

stack-build service="vllm":
    @echo "🔧 Building container stack (service: {{service}})..."
    @DOCKER_API_VERSION=1.45 {{compose-stack}} build {{service}}

stack-up services="":
    @echo "🚀 Starting container stack..."
    @{{compose-stack}} --compatibility up -d {{services}}
    @{{compose-stack}} ps

stack-down:
    @echo "🛑 Stopping container stack..."
    @{{compose-stack}} down

stack-logs service="vllm":
    @echo "📜 Tailing logs for {{service}} (Ctrl+C to exit)..."
    @{{compose-stack}} logs -f {{service}}

# Run Blender MCP stdio server (for Claude Desktop)
run-mcp-stdio:
    @echo "🚀 Starting Blender MCP stdio server..."
    @echo "Connect this to Claude Desktop via config:"
    @echo '  "blender": {"command": "{{blender}}", "args": ["--background", "--python", "{{workspace}}/blender-mcp/blender_mcp_stdio.py"]}'
    "{{blender}}" --background --python {{workspace}}/blender-mcp/blender_mcp_stdio.py

# Run Blender MCP stdio server with GUI (for debugging)
run-mcp-stdio-gui:
    @echo "🚀 Starting Blender MCP stdio server (with GUI)..."
    "{{blender}}" --python {{workspace}}/blender-mcp/blender_mcp_stdio.py

# ============================================================================
# Build & Package - Create distributable Blender extensions
# ============================================================================

# Prepare extension directory for packaging
prepare-extension:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Preparing extension for packaging..."

    BUILD_DIR="{{workspace}}/build/blender-mcp-extension"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"

    # Copy core files
    cp {{workspace}}/blender-mcp/blender_manifest.toml "$BUILD_DIR/"
    cp {{workspace}}/blender-mcp/addon.py "$BUILD_DIR/"
    cp {{workspace}}/blender-mcp/blender_mcp_stdio.py "$BUILD_DIR/"

    # Create __init__.py (extension entry point)
    cat > "$BUILD_DIR/__init__.py" << 'INITPY'
    # Blender MCP Extension
    # Model Context Protocol integration for Blender

    bl_info = {
        "name": "Blender MCP",
        "author": "Elastic Dot Ventures",
        "version": ({{extension_version_tuple}}),
        "blender": (4, 2, 0),
        "location": "View3D > Sidebar > BlenderMCP",
        "description": "Model Context Protocol integration for Claude AI and LLM agents",
        "category": "Interface",
    }

    # Import addon functionality
    from . import addon

    # Register/unregister hooks
    def register():
        addon.register()

    def unregister():
        addon.unregister()

    if __name__ == "__main__":
        register()
    INITPY

    # Create README
    cat > "$BUILD_DIR/README.md" << 'README'
    # Blender MCP Extension

    Model Context Protocol integration for Blender, enabling AI agents like Claude to interact with Blender.

    ## Features

    - 🎨 Scene inspection and manipulation
    - 🖼️ Asset integration (PolyHaven, Sketchfab)
    - 🤖 AI-powered 3D generation (Hyper3D Rodin)
    - 🔌 MCP stdio server for Claude Desktop
    - 📡 TCP socket server for custom integrations

    ## Installation

    1. Download the `.zip` file
    2. Open Blender → Edit → Preferences → Add-ons
    3. Click "Install" and select the `.zip` file
    4. Enable "Blender MCP"

    ## Usage

    ### With Claude Desktop

    Add to your Claude Desktop config (`~/.config/claude-desktop/claude_desktop_config.json`):

    \`\`\`json
    {
      "mcpServers": {
        "blender": {
          "command": "blender",
          "args": ["--background", "--python", "/path/to/blender_mcp_stdio.py"]
        }
      }
    }
    \`\`\`

    ### With Blender UI

    1. Open Blender
    2. View3D → Sidebar (press N) → BlenderMCP tab
    3. Configure API keys (optional)
    4. Click "Connect to MCP server"

    ## Documentation

    - GitHub: https://github.com/elasticdotventures/blender-awesome
    - MCP Protocol: https://modelcontextprotocol.io

    ## License

    MIT License - See LICENSE file
    README

    # Create LICENSE
    cat > "$BUILD_DIR/LICENSE" << 'LICENSE'
    MIT License

    Copyright (c) 2025 Elastic Dot Ventures

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
    LICENSE

    echo "✅ Extension prepared at: $BUILD_DIR"
    ls -la "$BUILD_DIR"

# Build extension package (manual zip)
build-extension: prepare-extension
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Building extension package..."

    BUILD_DIR="{{workspace}}/build/blender-mcp-extension"
    OUTPUT_DIR="{{workspace}}/dist"
    mkdir -p "$OUTPUT_DIR"

    # Create zip file
    cd "$BUILD_DIR"
    ZIP_FILE="$OUTPUT_DIR/blender-mcp-extension-v{{extension_version}}.zip"
    rm -f "$ZIP_FILE"

    if command -v zip >/dev/null 2>&1; then
        zip -r "$ZIP_FILE" .
    else
        # Fallback to python
        python -m zipfile -c "$ZIP_FILE" ./*
    fi

    echo "✅ Extension packaged: $ZIP_FILE"
    ls -lh "$ZIP_FILE"

# Build extension using Blender's CLI (official method)
build-extension-cli: prepare-extension
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📦 Building extension with Blender CLI..."

    BUILD_DIR="{{workspace}}/build/blender-mcp-extension"
    OUTPUT_DIR="{{workspace}}/dist"
    mkdir -p "$OUTPUT_DIR"

    # Use Blender's extension build command
    "{{blender}}" --command extension build \
        --source-dir "$BUILD_DIR" \
        --output-dir "$OUTPUT_DIR"

    echo "✅ Extension built with Blender CLI"
    ls -lh "$OUTPUT_DIR"

# Validate extension package
validate-extension:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🔍 Validating extension package..."

    ZIP_FILE="{{workspace}}/dist/blender-mcp-extension-v{{extension_version}}.zip"

    if [ ! -f "$ZIP_FILE" ]; then
        echo "❌ Extension package not found. Run: just build-extension"
        exit 1
    fi

    # Check if Blender 4.2+ supports validation
    if "{{blender}}" --help 2>&1 | grep -q "extension validate"; then
        "{{blender}}" --command extension validate "$ZIP_FILE"
        echo "✅ Extension validated successfully"
    else
        echo "⚠️  Blender extension validation not available (requires Blender 4.2+)"
        echo "📋 Performing manual checks..."

        # Manual validation
        unzip -l "$ZIP_FILE" | grep -q "blender_manifest.toml" && echo "  ✅ blender_manifest.toml present" || echo "  ❌ Missing blender_manifest.toml"
        unzip -l "$ZIP_FILE" | grep -q "__init__.py" && echo "  ✅ __init__.py present" || echo "  ❌ Missing __init__.py"
        unzip -l "$ZIP_FILE" | grep -q "addon.py" && echo "  ✅ addon.py present" || echo "  ❌ Missing addon.py"
        unzip -l "$ZIP_FILE" | grep -q "README.md" && echo "  ✅ README.md present" || echo "  ❌ Missing README.md"
        unzip -l "$ZIP_FILE" | grep -q "LICENSE" && echo "  ✅ LICENSE present" || echo "  ❌ Missing LICENSE"

        echo "✅ Manual validation complete"
    fi

# Install extension to system Blender
install-extension: build-extension
    #!/usr/bin/env bash
    set -euo pipefail
    echo "📥 Installing extension to Blender..."

    ZIP_FILE="{{workspace}}/dist/blender-mcp-extension-v{{extension_version}}.zip"

    # Check if Blender 4.2+ supports extension install
    if "{{blender}}" --help 2>&1 | grep -q "extension install"; then
        "{{blender}}" --command extension install "$ZIP_FILE"
        echo "✅ Extension installed via Blender CLI"
    else
        echo "⚠️  Blender extension CLI not available (requires Blender 4.2+)"
        echo "📦 Installing manually to addons directory..."

        ADDON_DIR="{{addon_dir}}"
        INSTALL_DIR="$ADDON_DIR/blender-mcp-extension"

        # Remove old version
        rm -rf "$INSTALL_DIR"

        # Extract to addons directory
        mkdir -p "$INSTALL_DIR"
        unzip -q "$ZIP_FILE" -d "$INSTALL_DIR"

        echo "✅ Extension installed manually to: $INSTALL_DIR"
    fi

    # Enable the addon
    "{{blender}}" --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender-mcp-extension'); bpy.ops.wm.save_userpref()"
    echo "✅ Extension enabled"

# Full build pipeline: prepare → build → validate
package-extension: prepare-extension build-extension validate-extension
    @echo ""
    @echo "🎉 Extension packaging complete!"
    @echo ""
    @echo "📦 Package: {{workspace}}/dist/blender-mcp-extension-v{{extension_version}}.zip"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Test install: just install-extension"
    @echo "  2. Validate: just validate-extension"
    @echo "  3. Share: Upload to GitHub releases or Blender Extensions platform"

# Clean build artifacts
clean-build:
    @echo "🧹 Cleaning build artifacts..."
    rm -rf {{workspace}}/build/
    rm -rf {{workspace}}/dist/
    @echo "✅ Build artifacts cleaned"

# Create GitHub release with extension
release version:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "🚀 Creating GitHub release v{{version}}..."

    # Build extension
    just build-extension

    ZIP_FILE="{{workspace}}/dist/blender-mcp-extension-v{{version}}.zip"

    if [ ! -f "$ZIP_FILE" ]; then
        echo "❌ Extension package not found"
        exit 1
    fi

    # Create GitHub release
    cd {{workspace}}
    gh release create "v{{version}}" \
        "$ZIP_FILE" \
        --title "Blender MCP Extension v{{version}}" \
        --notes "Model Context Protocol integration for Blender {{version}}" \
        --draft

    echo "✅ Draft release created: v{{version}}"
    echo "Visit GitHub to publish the release"

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

# Create Claude Desktop config
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
setup-all: detect-blender install-mcp-addon enable-mcp-addon install-phobos install-mcp-server setup-claude-config
    @echo "✅ Complete setup finished!"
    @echo ""
    @echo "Next steps:"
    @echo "  1. Start Blender: {{blender}}"
    @echo "  2. Test MCP: just test-mcp"
    @echo "  3. Open Claude Desktop and use Blender tools"

# Start Blender with MCP addon
start-blender:
    @echo "🎨 Starting Blender with MCP addon..."
    "{{blender}}" --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon')"

# Start Blender headless with MCP
start-blender-headless:
    @echo "🎨 Starting Blender headless with MCP..."
    "{{blender}}" --background --python-expr "import bpy; bpy.ops.preferences.addon_enable(module='blender_mcp_addon'); import time; time.sleep(999999)"

# Run example Blender script
run-example script="blender_python_example.py":
    @echo "🐍 Running {{script}}..."
    "{{blender}}" --background --python {{workspace}}/scripts/{{script}}

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
    command -v "{{blender}}" >/dev/null 2>&1 && echo "✅ blender" || echo "❌ blender (run: just detect-blender)"
    command -v docker >/dev/null 2>&1 && echo "✅ docker" || echo "❌ docker"
    command -v docker-compose >/dev/null 2>&1 && echo "✅ docker-compose" || echo "❌ docker-compose"
    command -v uv >/dev/null 2>&1 && echo "✅ uv" || echo "❌ uv"
    command -v gh >/dev/null 2>&1 && echo "✅ gh" || echo "❌ gh"
    command -v jupyter >/dev/null 2>&1 && echo "✅ jupyter" || echo "❌ jupyter"
    command -v python >/dev/null 2>&1 && echo "✅ python" || echo "❌ python"
    command -v git >/dev/null 2>&1 && echo "✅ git" || echo "❌ git"
    echo ""
    echo "Blender path: {{blender}}"
    echo "Addon dir: {{addon_dir}}"
    echo "Workspace: {{workspace}}"
docs-download:
    wget --mirror --convert-links --adjust-extension --page-requisites --no-parent https://docs.blender.org/api/current
extension_version := `python3 - <<'PY'
import tomllib
from pathlib import Path
data = tomllib.loads(Path("blender-mcp/pyproject.toml").read_text())
print(data["project"]["version"])
PY`

extension_version_tuple := `python3 - <<'PY'
import tomllib
from pathlib import Path
data = tomllib.loads(Path("blender-mcp/pyproject.toml").read_text())
parts = data["project"]["version"].split(".")
parts = (parts + ["0", "0"])[:3]
nums = [str(int(p)) for p in parts]
print(", ".join(nums))
PY`
