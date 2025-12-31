# Stage 1: Build stage with all tools needed for installation
FROM debian:trixie-slim AS builder

# Install only what's needed to get Volta and dev tools installed
RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    gnupg \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create node user for Volta installation
RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Install Volta as node user
USER node
ENV VOLTA_HOME=/home/node/.volta
ENV PATH=$VOLTA_HOME/bin:$PATH

RUN curl https://get.volta.sh | bash

# Install Node and pnpm via Volta
RUN volta install node@20
RUN volta install pnpm

# Install diff-so-fancy via npm
RUN npm install -g diff-so-fancy

# Fetch eza GPG key in builder stage
RUN mkdir -p /tmp/apt-keyrings \
    && wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /tmp/apt-keyrings/gierens.gpg

# Stage 2: Minimal runtime image
FROM debian:trixie-slim

# Install runtime dependencies and dev tools
RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends \
    # Required for Node.js runtime and TLS
    libc6 \
    libssl3 \
    # Volta needs these
    ca-certificates \
    # Development CLI tools
    bat \
    jq \
    ripgrep \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy eza GPG key from builder and add repository
COPY --from=builder /tmp/apt-keyrings/gierens.gpg /etc/apt/keyrings/gierens.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" > /etc/apt/sources.list.d/gierens.list \
    && chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list \
    && apt update \
    && apt -y install --no-install-recommends eza \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Remove package manager and other unnecessary tools
RUN rm -rf /usr/bin/apt* \
    /usr/bin/dpkg* \
    /usr/bin/gpg* \
    /usr/bin/curl \
    /usr/bin/wget \
    /usr/bin/perl* \
    /usr/sbin/adduser \
    /usr/sbin/deluser \
    /var/cache/apt \
    /var/lib/apt \
    /var/log/* \
    /usr/share/man \
    /usr/share/doc

# Create node user
RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# Copy Volta and Node installations from builder
COPY --from=builder --chown=node:node /home/node/.volta /home/node/.volta

# Copy diff-so-fancy symlink from builder (installed as global npm package)
# diff-so-fancy will be available via Volta's bin directory
COPY --from=builder --chown=node:node /home/node/.volta/bin/diff-so-fancy /home/node/.volta/bin/diff-so-fancy

# Set up environment
USER node
ENV VOLTA_HOME=/home/node/.volta
ENV PATH=$VOLTA_HOME/bin:$PATH
ENV NODE_OPTIONS="--no-warnings"

# Create workspace directory
RUN mkdir -p /home/node/workspace

WORKDIR /home/node/workspace

# Verify installations
RUN node --version && pnpm --version

# Default to bash shell for interactive development
SHELL ["/bin/bash", "-i", "-c"]

# Metadata
LABEL org.opencontainers.image.title="Chromamancer Development Container"
LABEL org.opencontainers.image.description="Hardened Debian Trixie container with Volta-managed Node.js and pnpm for chromamancer theme conversion tool development"