#!/usr/bin/env bash

set -euo pipefail

is-command() {
    command -v "$1" > /dev/null
}

install-ccache() {
    is-command ccache || sudo apt install ccache
    ccache --max-files 0 --max-size 0
    for compiler in cc c++ gcc g++ clang clang++; do
        ln --symbolic --force "$(which "${compiler}")" ~/.local/bin/ccache
    done
}

install-opam() {
    is-command opam && return
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
    opam init
}

install-cargo() {
    is-command cargo && return
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

cargo-has() {
    local exe_name="$1" 
    [[ -f "${CARGO_HOME:-$HOME/.cargo}/bin/$exe_name" ]]
}

cargo-install() {
    local package_name="$1"
    local exe_name="$2"
    if [[ "$exe_name" == "" ]]; then
        exe_name="$package_name"
    fi
    cargo-has "$exe_name" || cargo quickinstall "$package_name" 
}

install-from-opam() {
    install-opam
}

install-from-cargo() {
    install-cargo
    cargo-has cargo-quickinstall || cargo install cargo-quickinstall
    cargo-install just
    cargo-install ripgrep rg
    cargo-install fd-find fd
    cargo-install sd
    cargo-install exa
    cargo-install gitui
    cargo-install git-delta delta
    cargo-install tokei
    cargo-install skim sk
    cargo-install hyperfine
}

install-from-vscode() {
    is-command code || return
    code --install-extension ocamllabs.ocaml-platform
}

install-volta() {
    is-command volta && return
    curl https://get.volta.sh | bash
    . ~/.bashrc
}

npm-install() {
    local package_name="$1"
    local exe_name="$2"
    if [[ "$exe_name" == "" ]]; then
        exe_name="$package_name"
    fi
    is-command "$exe_name" || volta install "$package_name" 
}

install-from-npm() {
    install-volta
    volta install node@latest
    npm-install esy
}

install-build() {
    install-ccache &
    install-from-opam &
    install-from-npm &
    wait
    esy
}

install-dev-only() {
    install-from-cargo &
    install-from-vscode &
    wait
}

install-dev() {
    install-build &
    install-dev-only &
    wait
}

case "${1:-}" in
    "build")
        install-build
        ;;
    "dev")
        install-dev
        ;;
    *)
        echo >&2 "usage: ${0} [build|dev]"
        exit 1
        ;;
esac
