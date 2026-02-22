#!/usr/bin/env bash
set -euo pipefail

info() { printf '\033[1;32m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }

IS_BLUEFIN=false
IS_DEVCONTAINER=false
IS_DISTROBOX=false
USE_HOMEBREW=false
SUDO_CMD=()

NVIM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
PLUGINS_DIR="$NVIM_DIR/lua/custom/plugins"
FORCE_REPLACE=false
COPIED_FILES=()

if [[ "${1:-}" == "--force" ]]; then
  FORCE_REPLACE=true
fi
configure_environment() {
  if [[ $(id -u) -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
    SUDO_CMD=(sudo)
  fi

  if [[ -f /etc/os-release ]] && rg -qi 'bluefin' /etc/os-release; then
    IS_BLUEFIN=true
  fi

  if [[ -n "${DEVCONTAINER:-}" ]] || [[ -d /.devcontainer ]] || [[ -d /workspaces ]]; then
    IS_DEVCONTAINER=true
  fi

  if [[ -n "${DISTROBOX_ENTER_PATH:-}" ]] || [[ -n "${DISTROBOX_HOST_HOME:-}" ]] || [[ -n "${CONTAINER_ID:-}" && "${CONTAINER_ID}" == distrobox* ]]; then
    IS_DISTROBOX=true
  fi

  if [[ "$IS_BLUEFIN" == true ]] || [[ "$IS_DEVCONTAINER" == true ]] || [[ "$IS_DISTROBOX" == true ]]; then
    USE_HOMEBREW=true
  fi
}

install_homebrew_if_missing() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  if ! command -v curl >/dev/null 2>&1; then
    warn 'curl is required to install Homebrew automatically. Install curl first.'
    return
  fi

  info 'Installing Homebrew via curl (non-interactive)'
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    warn 'Homebrew installation failed. Falling back to system package manager if available.'
    return
  }

  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  elif [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
    eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
  fi
}

backup_and_copy() {
  local src="$1"
  local dst="$2"

  if [[ -f "$dst" ]]; then
    cp "$dst" "$dst.bak.$(date +%s)"
    warn "Backed up $dst"
  fi

  cp "$src" "$dst"
  info "Installed $(basename "$dst")"
  COPIED_FILES+=("$dst")
}

install_package_manager_deps() {
  if [[ "$USE_HOMEBREW" == true ]]; then
    info 'Detected Bluefin/devcontainer/distrobox workflow; preferring Homebrew dependencies'
    install_homebrew_if_missing
  fi

  if command -v brew >/dev/null 2>&1; then
    info 'Detected Homebrew'
    brew update
    brew install git curl unzip ripgrep fd node dotnet neovim || warn 'One or more brew installs failed.'
  elif command -v apt-get >/dev/null 2>&1; then
    info 'Detected apt-based system'
    "${SUDO_CMD[@]}" apt-get update
    "${SUDO_CMD[@]}" apt-get install -y git curl unzip ripgrep fd-find build-essential ca-certificates gnupg

    if ! command -v node >/dev/null 2>&1; then
      curl -fsSL https://deb.nodesource.com/setup_20.x | "${SUDO_CMD[@]}" -E bash -
      "${SUDO_CMD[@]}" apt-get install -y nodejs
    fi

    if ! command -v nvim >/dev/null 2>&1; then
      "${SUDO_CMD[@]}" apt-get install -y neovim
    fi

    if ! command -v dotnet >/dev/null 2>&1; then
      . /etc/os-release
      if [[ "$ID" == "ubuntu" ]]; then
        curl -fsSL "https://packages.microsoft.com/config/ubuntu/${VERSION_ID}/packages-microsoft-prod.deb" -o packages-microsoft-prod.deb || true
      elif [[ "$ID" == "debian" ]]; then
        curl -fsSL "https://packages.microsoft.com/config/debian/${VERSION_ID}/packages-microsoft-prod.deb" -o packages-microsoft-prod.deb || true
      else
        warn 'Unsupported apt distro for automatic dotnet repo setup; install dotnet manually.'
      fi

      if [[ -f packages-microsoft-prod.deb ]]; then
        "${SUDO_CMD[@]}" dpkg -i packages-microsoft-prod.deb
        rm -f packages-microsoft-prod.deb
        "${SUDO_CMD[@]}" apt-get update
        "${SUDO_CMD[@]}" apt-get install -y dotnet-sdk-8.0 || warn 'Failed to install dotnet-sdk-8.0 via apt.'
      fi
    else
      info 'dotnet already installed, skipping SDK repo setup.'
    fi
  elif command -v dnf >/dev/null 2>&1; then
    info 'Detected dnf-based system'
    "${SUDO_CMD[@]}" dnf install -y git curl unzip ripgrep fd-find nodejs dotnet-sdk-8.0 neovim
  elif command -v pacman >/dev/null 2>&1; then
    info 'Detected pacman-based system'
    "${SUDO_CMD[@]}" pacman -Sy --noconfirm git curl unzip ripgrep fd nodejs dotnet-sdk neovim
  else
    warn 'Unrecognized package manager. Install dependencies manually.'
  fi
}

install_rust_toolchain() {
  if ! command -v cargo >/dev/null 2>&1; then
    info 'Installing Rust toolchain'
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # shellcheck disable=SC1090
    source "$HOME/.cargo/env"
  else
    info 'Rust already installed'
  fi

  if ! command -v leptosfmt >/dev/null 2>&1; then
    cargo install leptosfmt || warn 'Failed to install leptosfmt'
  fi
}

install_ai_clis() {
  if command -v npm >/dev/null 2>&1; then
    npm install -g @kilocode/cli @openai/codex || warn 'Failed to install Kilo/Codex CLIs'
  else
    warn 'npm not found; skipping Kilo/Codex CLI install'
  fi

  if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash || warn 'Failed to install Claude CLI'
  fi

  if command -v dotnet >/dev/null 2>&1; then
    if ! dotnet tool list -g | grep -q EasyDotnet; then
      dotnet tool install -g EasyDotnet || warn 'Failed to install EasyDotnet tool'
    fi
  fi
}

copy_configuration() {
  mkdir -p "$PLUGINS_DIR"

  if [[ "$FORCE_REPLACE" == true ]]; then
    rm -rf "$NVIM_DIR/lua/custom"
    mkdir -p "$PLUGINS_DIR"
  fi

  for file in lua/custom/plugins/*.lua; do
    backup_and_copy "$file" "$PLUGINS_DIR/$(basename "$file")"
  done
}

sync_neovim_plugins() {
  if ! command -v nvim >/dev/null 2>&1; then
    warn 'nvim not available, skipping plugin sync'
    return
  fi

  info 'Running Lazy sync'
  nvim --headless '+Lazy! sync' '+qa' || warn 'Lazy sync failed'

  info 'Running Mason install'
  nvim --headless '+MasonInstall! rust-analyzer roslyn codelldb netcoredbg' '+qa' || warn 'Mason install failed'

  if command -v rust-analyzer >/dev/null 2>&1; then
    info 'Verified rust-analyzer is available on PATH.'
  else
    warn 'rust-analyzer is not on PATH (it may still be installed in Mason).'
  fi
}

configure_environment
install_package_manager_deps
install_rust_toolchain
install_ai_clis
copy_configuration
sync_neovim_plugins

info 'Copied/updated plugin files:'
for f in "${COPIED_FILES[@]}"; do
  info " - $f"
done

info 'Installation complete.'
