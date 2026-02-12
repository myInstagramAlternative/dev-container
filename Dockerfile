FROM ubuntu:24.04

ARG TARGETARCH
LABEL version="1.0.0"

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Initializing - install basic tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gpg \
    software-properties-common \
    build-essential \
    dnsutils \
    unzip \
    jq \
    tmux \
    ncdu \
    fzf \
    lsb-release \
    ca-certificates \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest git from PPA
RUN add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Nushell
ENV NUSHELL_VERSION=0.103.0
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    wget https://github.com/nushell/nushell/releases/download/${NUSHELL_VERSION}/nu-${NUSHELL_VERSION}-${dockerArch}.tar.gz \
    && tar -xvf nu-${NUSHELL_VERSION}-${dockerArch}.tar.gz \
    && rm nu-${NUSHELL_VERSION}-${dockerArch}.tar.gz \
    && install nu-${NUSHELL_VERSION}-${dockerArch}/nu /usr/local/bin/ \
    && rm -rf nu-${NUSHELL_VERSION}-${dockerArch}

# Install Neovim
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64' ;; \
    arm64) dockerArch='arm64' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${dockerArch}.tar.gz \
    && tar -xzf nvim-linux-${dockerArch}.tar.gz \
    && rm nvim-linux-${dockerArch}.tar.gz \
    && mkdir -p /usr/local/share/nvim \
    && mv nvim-linux-${dockerArch}/bin/nvim /usr/local/bin/ \
    && mv nvim-linux-${dockerArch}/share/nvim/runtime/* /usr/local/share/nvim \
    && rm -rf nvim-linux-${dockerArch}

# Install opencode
RUN curl -fsSL https://opencode.ai/install | bash

# Install zoxide
ENV ZOXIDE_VERSION=0.9.8
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    wget https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && tar -xvf zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && rm zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && install zoxide /usr/local/bin/

# Install YQ
ENV YQ_VERSION=4.47.2
RUN wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install BAT
ENV BAT_VERSION=0.25.0
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    wget https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-v${BAT_VERSION}-${dockerArch}.tar.gz \
    && tar -xvf bat-v${BAT_VERSION}-${dockerArch}.tar.gz \
    && rm bat-v${BAT_VERSION}-${dockerArch}.tar.gz \
    && install bat-v${BAT_VERSION}-${dockerArch}/bat /usr/local/bin/ \
    && rm -rf bat-v${BAT_VERSION}-${dockerArch}

# Install kubectl
RUN curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" \
    && install kubectl /usr/local/bin/

# Install fluxcd
ENV FLUX2_VERSION=2.7.0
RUN curl -L -o fluxcd.tar.gz https://github.com/fluxcd/flux2/releases/download/v${FLUX2_VERSION}/flux_${FLUX2_VERSION}_linux_${TARGETARCH}.tar.gz \
    && tar -xzf fluxcd.tar.gz \
    && rm fluxcd.tar.gz \
    && mv ./flux /usr/local/bin/

# Install helm
ENV HELM_VERSION=3.19.0
RUN wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz \
    && tar -xzf helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz \
    && rm helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz \
    && mv linux-${TARGETARCH}/helm /usr/local/bin/

# Install k9s
ENV K9S_VERSION=0.50.13
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='Linux_amd64' ;; \
    arm64) dockerArch='Linux_arm64' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    wget https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_${dockerArch}.tar.gz \
    && tar -xzf k9s_${dockerArch}.tar.gz \
    && rm k9s_${dockerArch}.tar.gz \
    && mv k9s /usr/local/bin/

# Install starship
ENV STARSHIP_VERSION=1.23.0
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    wget https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${dockerArch}.tar.gz \
    && tar -xzf starship-${dockerArch}.tar.gz \
    && rm starship-${dockerArch}.tar.gz \
    && mv starship /usr/local/bin/

# Install Golang
ENV GOLANG_VERSION=1.24.1
RUN wget "https://go.dev/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz \
    && rm go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install Node.js (from NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install fnm (Fast Node Manager)
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir /usr/local/bin

# Install Rust (as root for now)
ENV HOME=/root
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && . $HOME/.cargo/env \
    && rustup component add rust-analyzer clippy rustfmt
ENV PATH=$PATH:/root/.cargo/bin

# Install Python and pip
RUN apt-get update \
    && apt-get install -y python3 python3-pip python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install UV (Astral's Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && mv /root/.local/bin/uv /usr/local/bin/ \
    && mv /root/.local/bin/uvx /usr/local/bin/

# Install Python Poetry
ENV POETRY_VERSION=1.8.5
RUN curl -sSL https://install.python-poetry.org | python3 - \
    && mv /root/.local/bin/poetry /usr/local/bin/

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Bicep CLI
RUN az bicep install

# Create jesteibice user
RUN useradd -m -s /usr/local/bin/nu -G sudo jesteibice \
    && echo "jesteibice ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy dotconfig files to jesteibice's home
RUN mkdir -p /home/jesteibice/.config && \
    if [ -d dotconfig/nushell ]; then cp -r dotconfig/nushell /home/jesteibice/.config/; fi && \
    if [ -d dotconfig/nvim ]; then cp -r dotconfig/nvim /home/jesteibice/.config/; fi && \
    if [ -d dotconfig/helix ]; then cp -r dotconfig/helix /home/jesteibice/.config/; fi && \
    if [ -d dotconfig/tmux ]; then cp -r dotconfig/tmux /home/jesteibice/.config/; fi && \
    if [ -d dotconfig/atuin ]; then cp -r dotconfig/atuin /home/jesteibice/.config/; fi && \
    # Create mod.nu files for nushell modules if missing
    if [ -d /home/jesteibice/.config/nushell/modules ]; then \
        for dir in /home/jesteibice/.config/nushell/modules/*/; do \
            if [ -d "$dir" ] && [ ! -f "$dir/mod.nu" ]; then \
                touch "$dir/mod.nu"; \
            fi; \
        done; \
    fi && \
    # Create .nu.nu stub
    touch /home/jesteibice/.nu.nu && \
    # Initialize starship for nushell
    mkdir -p /home/jesteibice/.cache/starship && \
    starship init nu > /home/jesteibice/.cache/starship/init.nu && \
    # Fix ownership
    chown -R jesteibice:jesteibice /home/jesteibice

# Set default shell to nushell
SHELL ["/usr/local/bin/nu", "-c"]

# Switch to jesteibice user
USER jesteibice

# Set working directory
WORKDIR /home/jesteibice

# Default command
CMD ["/usr/local/bin/nu"]
