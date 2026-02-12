FROM ubuntu:24.04

LABEL version="1.0.0"

ARG TARGETARCH
ENV DEBIAN_FRONTEND=noninteractive

# Initialize and install base dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gpg \
    ca-certificates \
    lsb-release \
    software-properties-common \
    build-essential \
    dnsutils \
    unzip \
    git \
    jq \
    tmux \
    ncdu \
    fzf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest git from PPA
RUN add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# renovate: datasource=github-releases depName=nushell/nushell versioning=regex:^(?<major>\d+)\.(?<minor>\d+).(?<patch>\d+)$ extractVersion=^(?<version>.*)$
ENV NUSHELL_VERSION=0.103.0
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
    && install nu-${NUSHELL_VERSION}-${dockerArch}/nu_* /usr/local/bin/ \
    && rm -rf nu-${NUSHELL_VERSION}-${dockerArch}

# Install NeoVim
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
RUN curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path \
    && ln -s $HOME/.opencode/bin/opencode /usr/local/bin/opencode

# Install Python (with deadsnakes PPA for latest versions)
RUN add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.12 python3.12-venv python3.12-dev python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Install uv (Astral's Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv $HOME/.local/bin/uv /usr/local/bin/ \
    && mv $HOME/.local/bin/uvx /usr/local/bin/

# Install Node.js (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Golang
ENV GOLANG_VERSION=1.23.5
RUN wget "https://go.dev/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz \
    && rm go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && . $HOME/.cargo/env \
    && rustup component add rust-analyzer clippy rustfmt
ENV PATH=$PATH:$HOME/.cargo/bin

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Bicep CLI (standalone)
RUN case "${TARGETARCH}" in \
    amd64) bicepArch='x64' ;; \
    arm64) bicepArch='arm64' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;; \
    esac; \
    curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-${bicepArch} \
    && chmod +x bicep \
    && mv bicep /usr/local/bin/

# Install Azure Bicep extension for Azure CLI
RUN az bicep install

# Install additional useful tools

# renovate: datasource=github-releases depName=ajeetdsouza/zoxide versioning=regex:^(?<major>\d+)\.(?<minor>\d+).(?<patch>\d+)$ extractVersion=^v(?<version>.*)$
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

# renovate: datasource=github-releases depName=starship/starship versioning=regex:^(?<major>\d+)\.(?<minor>\d+).(?<patch>\d+)$ extractVersion=^v(?<version>.*)$
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

# renovate: datasource=github-releases depName=sharkdp/bat versioning=regex:^(?<major>\d+)\.(?<minor>\d+).(?<patch>\d+)$ extractVersion=^v(?<version>.*)$
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

# renovate: datasource=github-releases depName=mikefarah/yq versioning=regex:^(?<major>\d+)\.(?<minor>\d+).(?<patch>\d+)$ extractVersion=^v(?<version>.*)$
ENV YQ_VERSION=4.47.2
RUN wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Setup environment
ENV PATH="/usr/local/bin:$PATH"
ENV GOPATH="/go"
ENV PATH="$GOPATH/bin:$PATH"

# Create workspace directory
WORKDIR /workspace

# Set default shell to nushell
SHELL ["/usr/local/bin/nu", "-c"]

# Default command
CMD ["/usr/local/bin/nu"]
