# Ubuntu 22.04 with Python 3.11 for compatibility with Blender 4+
FROM ubuntu:22.04

# Avoid interactive prompts during build
ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Base development tools
    build-essential \
    cmake \
    git \
    curl \
    wget \
    unzip \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release \
    # Graphics and X11 support for Blender GUI
    xvfb \
    x11-apps \
    libx11-dev \
    libxrender1 \
    libxtst6 \
    libxrandr2 \
    libxi6 \
    libgl1-mesa-glx \
    libglu1-mesa \
    libxss1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxinerama1 \
    libxkbcommon0 \
    # Audio libraries (for Blender)
    libasound2 \
    pulseaudio \
    # Python and development
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    # Additional tools
    vim \
    nano \
    htop \
    tree \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# Install Node.js 20 (for Claude Code and MCP servers)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Rust (for nyx-space and other Rust tools)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Docker CLI for Docker-in-Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && usermod -aG sudo $USERNAME \
    && usermod -aG docker $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME

# Install UV package manager for Python
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Switch to non-root user for remaining operations
USER $USERNAME
WORKDIR /home/$USERNAME

# Install UV for the user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/$USERNAME/.local/bin:${PATH}"

# Install Rust for the user
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/$USERNAME/.cargo/bin:${PATH}"

# Download and install Blender 4.2 LTS
ENV BLENDER_VERSION=4.2.0
ENV BLENDER_PATH=/opt/blender
ENV BLENDER_MAJOR=4.2
RUN sudo mkdir -p $BLENDER_PATH \
    && cd /tmp \
    && wget -q https://download.blender.org/release/Blender${BLENDER_MAJOR}/blender-${BLENDER_VERSION}-linux-x64.tar.xz \
    && sudo tar -xf blender-${BLENDER_VERSION}-linux-x64.tar.xz -C $BLENDER_PATH --strip-components=1 \
    && rm blender-${BLENDER_VERSION}-linux-x64.tar.xz \
    && sudo ln -s $BLENDER_PATH/blender /usr/local/bin/blender

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create Python virtual environment for the project
RUN uv venv /home/$USERNAME/.venv
ENV PATH="/home/$USERNAME/.venv/bin:${PATH}"

# Install core Python packages for the generative CAD workflow
RUN uv pip install \
    # Core scientific stack
    numpy \
    scipy \
    matplotlib \
    jupyter \
    ipykernel \
    # 3D and mesh processing
    trimesh \
    meshio \
    open3d \
    # Robotics and simulation
    mujoco \
    gymnasium \
    "gymnasium[classic_control]" \
    stable-baselines3 \
    # URDF and robotics tools
    urdfpy \
    pinocchio \
    # Computer vision and AI
    opencv-python \
    torch \
    torchvision \
    # CAD and geometry
    cadquery \
    # MCP and agent tools
    uvicorn \
    fastapi \
    jinja2 \
    websockets \
    # Development tools
    black \
    pylint \
    pytest \
    # Blender Python API (if available)
    bpy || echo "bpy not available in PyPI, will use Blender's built-in"

# Install Rust-based aerospace tools
RUN cargo install --git https://github.com/nyx-space/nyx --branch main nyx-space-cli || echo "nyx-space build may require more resources"

# Set up Jupyter kernel
RUN python -m ipykernel install --user --name blender-awesome --display-name "Blender Awesome"

# Create workspace directory
RUN sudo mkdir -p /workspace && sudo chown $USERNAME:$USERNAME /workspace

# Set environment variables for Blender Python integration
ENV BLENDER_PYTHON_PATH="$BLENDER_PATH/python/bin/python3.11"
ENV PYTHONPATH="/workspace:$BLENDER_PATH/python/lib/python3.11/site-packages:${PYTHONPATH}"

# Copy setup script
COPY setup.sh /home/$USERNAME/.devcontainer/setup.sh
RUN sudo chown $USERNAME:$USERNAME /home/$USERNAME/.devcontainer/setup.sh \
    && chmod +x /home/$USERNAME/.devcontainer/setup.sh

WORKDIR /workspace

# Default command
CMD ["/bin/bash"]