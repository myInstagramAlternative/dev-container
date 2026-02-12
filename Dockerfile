FROM ubuntu:24.04

ARG TARGETARCH
LABEL version="1.0.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV NUSHELL_VERSION=0.103.0
ENV HOME=/root

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    build-essential \
    dnsutils \
    jq \
    tmux \
    ncdu \
    fzf \
    && rm -rf /var/lib/apt/lists/*

# Install latest git from PPA
RUN add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

# Install Nushell
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;; \
    esac; \
    wget https://github.com/nushell/nushell/releases/download/${NUSHELL_VERSION}/nu-${NUSHELL_VERSION}-${dockerArch}.tar.gz \
    && tar -xzf nu-${NUSHELL_VERSION}-${dockerArch}.tar.gz \
    && rm nu-${NUSHELL_VERSION}-${dockerArch}.tar.gz \
    && install nu-${NUSHELL_VERSION}-${dockerArch}/nu /usr/local/bin/ \
    && rm -rf nu-${NUSHELL_VERSION}-${dockerArch}

# Install Neovim
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64' ;; \
    arm64) dockerArch='arm64' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;; \
    esac; \
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${dockerArch}.tar.gz \
    && tar -xzf nvim-linux-${dockerArch}.tar.gz \
    && rm nvim-linux-${dockerArch}.tar.gz \
    && mv nvim-linux-${dockerArch}/bin/nvim /usr/local/bin/ \
    && mkdir -p /usr/local/share/nvim \
    && mv nvim-linux-${dockerArch}/share/nvim/runtime/* /usr/local/share/nvim/ \
    && rm -rf nvim-linux-${dockerArch}

# Install opencode
RUN curl -fsSL https://opencode.ai/install | sh

# Install Starship
ENV STARSHIP_VERSION=1.23.0
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;; \
    esac; \
    wget https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${dockerArch}.tar.gz \
    && tar -xzf starship-${dockerArch}.tar.gz \
    && rm starship-${dockerArch}.tar.gz \
    && install starship /usr/local/bin/ \
    && rm starship

# Initialize starship for nushell
RUN mkdir -p ~/.cache/starship && starship init nu > ~/.cache/starship/init.nu

# Install zoxide
ENV ZOXIDE_VERSION=0.9.8
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;; \
    esac; \
    wget https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && tar -xzf zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && rm zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && install zoxide /usr/local/bin/ \
    && rm zoxide

# Install bat
ENV BAT_VERSION=0.25.0
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;; \
    esac; \
    wget https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-${dockerArch}.tar.gz \
    && tar -xzf bat-v${BAT_VERSION}-${dockerArch}.tar.gz \
    && rm bat-v${BAT_VERSION}-${dockerArch}.tar.gz \
    && install bat-v${BAT_VERSION}-${dockerArch}/bat /usr/local/bin/ \
    && rm -rf bat-v${BAT_VERSION}-${dockerArch}

# Install yq
ENV YQ_VERSION=4.47.2
RUN wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install Python and UV
RUN add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.12 python3.12-venv python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install UV
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv $HOME/.local/bin/uv /usr/local/bin/ \
    && mv $HOME/.local/bin/uvx /usr/local/bin/

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Golang
ENV GOLANG_VERSION=1.23.5
RUN wget "https://go.dev/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && rm -rf /usr/local/go && tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz \
    && rm go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && . $HOME/.cargo/env \
    && rustup component add rust-analyzer clippy rustfmt
ENV PATH=$PATH:$HOME/.cargo/bin

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Bicep CLI
RUN az bicep install

# Copy dotconfig files
COPY dotconfig/nushell /root/.config/nushell
COPY dotconfig/nvim /root/.config/nvim
COPY dotconfig/helix /root/.config/helix
COPY dotconfig/tmux /root/.config/tmux
COPY dotconfig/atuin /root/.config/atuin

# Create stub .nu.nu file if it doesn't exist (will be overwritten by volume mount if local file exists)
RUN touch ~/.nu.nu

# Set default shell to nushell
SHELL ["/usr/local/bin/nu", "-c"]

# Default command
CMD ["/usr/local/bin/nu"]
