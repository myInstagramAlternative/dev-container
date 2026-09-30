# syntax=docker/dockerfile:1

# Build the rathole client from source, cross-compiled on the BUILDPLATFORM so
# the arm64 image doesn't have to compile Rust under qemu emulation.
# Pinned to rathole main (17 commits past the last release, v0.5.0).
# Bump RATHOLE_REF by hand: renovate can't track a raw commit SHA cleanly.
FROM --platform=$BUILDPLATFORM rust:1-bookworm AS rathole-builder
ARG TARGETARCH
ENV RATHOLE_REF=a292f7ed5402f840415fc6a53827da2f34337856
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && if [ "${TARGETARCH}" = "arm64" ] && [ "$(dpkg --print-architecture)" != "arm64" ]; then \
         apt-get install -y --no-install-recommends gcc-aarch64-linux-gnu libc6-dev-arm64-cross; \
       fi \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone https://github.com/rathole-org/rathole.git . \
    && git checkout "${RATHOLE_REF}"
# client + noise only: no TLS backend, so no OpenSSL and cheap cross-compilation.
RUN case "${TARGETARCH}" in \
        amd64) triple=x86_64-unknown-linux-gnu ;; \
        arm64) triple=aarch64-unknown-linux-gnu ;; \
        *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;; \
    esac \
    && rustup target add "${triple}" \
    && if [ "${triple}" = "aarch64-unknown-linux-gnu" ] && [ "$(dpkg --print-architecture)" != "arm64" ]; then \
         export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc; \
       fi \
    && cargo build --release --locked --no-default-features --features client,noise --target "${triple}" \
    && install "target/${triple}/release/rathole" /usr/local/bin/rathole

FROM ubuntu:26.04

ARG TARGETARCH
LABEL version="1.0.1"

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Initializing - install basic tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gpg \
    openssh-server \
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
    procps \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install latest git from PPA
RUN add-apt-repository ppa:git-core/ppa -y \
    && apt-get update \
    && apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure git and SSH.
# Hardening lives in a drop-in (sshd_config Includes sshd_config.d/*.conf).
# No host keys are generated or shipped in the image: they are created at
# runtime in the entrypoint so every container has unique keys.
RUN git config --system --add safe.directory '*' \
    && mkdir -p /run/sshd /etc/ssh/sshd_config.d \
    && printf '%s\n' \
        'PermitRootLogin no' \
        'PubkeyAuthentication yes' \
        'PasswordAuthentication no' \
        'KbdInteractiveAuthentication no' \
        'PermitEmptyPasswords no' \
        'AuthenticationMethods publickey' \
        'UsePAM no' \
        'X11Forwarding no' \
        'AllowAgentForwarding no' \
        'AllowTcpForwarding yes' \
        'GatewayPorts no' \
        'AllowUsers jesteibice' \
        'MaxAuthTries 3' \
        'MaxSessions 10' \
        'LoginGraceTime 20' \
        'ClientAliveInterval 300' \
        'ClientAliveCountMax 2' \
        'PrintMotd no' \
        > /etc/ssh/sshd_config.d/99-hardening.conf \
    && chmod 644 /etc/ssh/sshd_config.d/99-hardening.conf \
    && chmod 755 /etc/ssh \
    && rm -f /etc/ssh/ssh_host_*

# Install Nushell
# renovate: datasource=github-releases depName=nushell/nushell
ENV NUSHELL_VERSION=0.116.0
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

# Install zoxide
# renovate: datasource=github-releases depName=ajeetdsouza/zoxide
ENV ZOXIDE_VERSION=0.10.0
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    wget https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && tar -xvf zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && rm zoxide-${ZOXIDE_VERSION}-${dockerArch}.tar.gz \
    && install zoxide /usr/local/bin/

# Install atuin (shell history)
# renovate: datasource=github-releases depName=atuinsh/atuin
ENV ATUIN_VERSION=18.23.0
RUN case "${TARGETARCH}" in \
    amd64) dockerArch='x86_64-unknown-linux-musl' ;; \
    arm64) dockerArch='aarch64-unknown-linux-musl' ;; \
    *) echo >&2 "error: unsupported architecture (${TARGETARCH})"; exit 1 ;;\
    esac; \
    wget https://github.com/atuinsh/atuin/releases/download/v${ATUIN_VERSION}/atuin-${dockerArch}.tar.gz \
    && tar -xvf atuin-${dockerArch}.tar.gz \
    && rm atuin-${dockerArch}.tar.gz \
    && install atuin-${dockerArch}/atuin /usr/local/bin/ \
    && rm -rf atuin-${dockerArch}

# Install YQ
# renovate: datasource=github-releases depName=mikefarah/yq
ENV YQ_VERSION=4.54.1
RUN wget https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH} -O /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install BAT
# renovate: datasource=github-releases depName=sharkdp/bat
ENV BAT_VERSION=0.26.1
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
# renovate: datasource=github-releases depName=fluxcd/flux2
ENV FLUX2_VERSION=2.9.5
RUN curl -L -o fluxcd.tar.gz https://github.com/fluxcd/flux2/releases/download/v${FLUX2_VERSION}/flux_${FLUX2_VERSION}_linux_${TARGETARCH}.tar.gz \
    && tar -xzf fluxcd.tar.gz \
    && rm fluxcd.tar.gz \
    && mv ./flux /usr/local/bin/

# Install helm
# renovate: datasource=github-releases depName=helm/helm
ENV HELM_VERSION=4.3.0
RUN wget https://get.helm.sh/helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz \
    && tar -xzf helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz \
    && rm helm-v${HELM_VERSION}-linux-${TARGETARCH}.tar.gz \
    && mv linux-${TARGETARCH}/helm /usr/local/bin/

# Install k9s
# renovate: datasource=github-releases depName=derailed/k9s
ENV K9S_VERSION=0.51.0
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
# renovate: datasource=github-releases depName=starship/starship
ENV STARSHIP_VERSION=1.26.0
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
# renovate: datasource=golang-version depName=golang/go
ENV GOLANG_VERSION=1.27.1
RUN wget "https://go.dev/dl/go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz \
    && rm go${GOLANG_VERSION}.linux-${TARGETARCH}.tar.gz
ENV PATH=$PATH:/usr/local/go/bin

# Install Node.js (from NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# OpenCode v2 (beta). Pinned to the `beta` dist-tag: some untagged snapshots
# rename the binary (e.g. `lildax`) or ship without a platform binary. Resolve
# whichever bin exists and smoke-test it, so a rename fails the build loudly
# instead of leaving a dangling `opencode` symlink.
# Config is shared at ~/.config/opencode (V2 translates V1 in-memory).
# renovate: datasource=npm depName=@opencode-ai/cli
ENV OPENCODE_VERSION=0.0.0-beta-19271
RUN set -eux; \
    npm install -g @opencode-ai/cli@"${OPENCODE_VERSION}"; \
    bin=""; \
    for c in opencode2 opencode lildax; do \
        if command -v "$c" > /dev/null 2>&1; then bin="$c"; break; fi; \
    done; \
    [ -n "$bin" ] || { echo >&2 "error: no opencode CLI binary found after install"; exit 1; }; \
    "$bin" --version; \
    ln -sf "$(command -v "$bin")" /usr/local/bin/opencode

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

# Install Python
RUN apt-get update \
    && apt-get install -y python3 python3-pip python3-venv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create jesteibice user
RUN useradd -m -s /usr/local/bin/nu -G sudo jesteibice \
    && echo "jesteibice ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy dotconfig files to jesteibice's home
COPY dotconfig/ /home/jesteibice/.config/

# Create mod.nu files for nushell modules if missing
RUN if [ -d /home/jesteibice/.config/nushell/modules ]; then \
        for dir in /home/jesteibice/.config/nushell/modules/*/; do \
            if [ -d "$dir" ] && [ ! -f "$dir/mod.nu" ]; then \
                touch "$dir/mod.nu"; \
            fi; \
        done; \
    fi && \
    chown -R jesteibice:jesteibice /home/jesteibice

# Switch to jesteibice user for user-specific installations
USER jesteibice
ENV HOME=/home/jesteibice

# Install fnm (Fast Node Manager) as jesteibice
RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell --install-dir $HOME/.local/bin

# Install Rust as jesteibice
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable \
    && . $HOME/.cargo/env \
    && rustup component add rust-analyzer clippy rustfmt

# Install UV (Astral's Python package manager) as jesteibice
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python Poetry as jesteibice
# renovate: datasource=github-releases depName=python-poetry/poetry
ENV POETRY_VERSION=2.5.1
RUN curl -sSL https://install.python-poetry.org | python3 -

# Create .nu.nu stub, initialize starship and zoxide as jesteibice
RUN touch $HOME/.nu.nu \
    && mkdir -p $HOME/.cache/starship \
    && starship init nu > $HOME/.cache/starship/init.nu \
    && zoxide init nushell > $HOME/.zoxide.nu

# Set up PATH for user tools
ENV PATH=$HOME/.cargo/bin:$HOME/.local/bin:$PATH

# Set default shell to nushell
SHELL ["/usr/local/bin/nu", "-c"]

# Set working directory
WORKDIR /home/jesteibice

# Expose SSH port
EXPOSE 22

# Entrypoint starts sshd then runs CMD
COPY --chmod=755 docker-entrypoint.sh /usr/local/bin/

# rathole client, built in the builder stage above
COPY --from=rathole-builder /usr/local/bin/rathole /usr/local/bin/rathole
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["/usr/local/bin/nu"]
