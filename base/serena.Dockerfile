# Custom Serena Docker image with proper user permissions
# Based on the official serena image but runs as non-root user

FROM python:3.11.13-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (same version as official image)
ENV NVM_VERSION=0.40.3
ENV NODE_VERSION=22.18.0
ENV NVM_DIR=/opt/nvm

RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && nvm alias default $NODE_VERSION

# Create serena user and group (will be remapped at runtime)
RUN groupadd -g 1000 serena && useradd -u 1000 -g serena -m -s /bin/bash serena

# Create workspace directory and set ownership
RUN mkdir -p /workspaces/serena && chown -R serena:serena /workspaces

# Switch to serena user
USER serena

# Install uv (Python package manager used by serena) as the serena user
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Set up environment paths
ENV PATH="/home/serena/.local/bin:/opt/nvm/versions/node/v${NODE_VERSION}/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Set working directory
WORKDIR /workspaces/serena

# Create virtual environment using uv
RUN uv venv .venv

# Activate virtual environment and install serena
# Note: We'll install serena from PyPI or copy from the official image
ENV PATH="/workspaces/serena/.venv/bin:${PATH}"

# Install serena from PyPI (if available) or we'll copy from official image
RUN . .venv/bin/activate && pip install --upgrade pip

# For now, let's copy the serena installation from the official image
# We'll do this in a multi-stage build
FROM ghcr.io/oraios/serena:latest as official

FROM python:3.11.13-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (same version as official image)
ENV NVM_VERSION=0.40.3
ENV NODE_VERSION=22.18.0
ENV NVM_DIR=/opt/nvm

RUN mkdir -p $NVM_DIR \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm use $NODE_VERSION \
    && nvm alias default $NODE_VERSION

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Create serena user and group
RUN groupadd -g 1000 serena && useradd -u 1000 -g serena -m -s /bin/bash serena

# Create workspace directory
RUN mkdir -p /workspaces/serena && chown -R serena:serena /workspaces

# Copy serena installation from official image
COPY --from=official --chown=serena:serena /workspaces/serena /workspaces/serena

# Copy uv installation
COPY --from=official /root/.local/bin/uv /home/serena/.local/bin/uv
RUN chown serena:serena /home/serena/.local/bin/uv

# Switch to serena user
USER serena

# Set up environment
ENV PATH="/home/serena/.local/bin:/workspaces/serena/.venv/bin:/opt/nvm/versions/node/v${NODE_VERSION}/bin:${PATH}"
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Set working directory
WORKDIR /workspaces/serena

# Entry point (same as official image but with proper user)
ENTRYPOINT ["/bin/bash", "-c", "source .venv/bin/activate && $0 $@"]
