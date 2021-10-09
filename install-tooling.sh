#!/usr/bin/env bash

set -e

is-command() {
    command -v "$1" > /dev/null
}

install-ccache() {
    sudo apt install ccache
    ccache --max-files 0 --max-size 0
    for compiler in cc c++ gcc g++ clang clang++; do
        ln --symbolic --force "$(which "${compiler}")" ~/.local/bin/ccache
    done
}

install-mold() {
    is-command mold && return
    sudo apt install git build-essential cmake ninja clang
    cd ~
    git clone https://github.com/rui314/mold.git
    cd mold
    git checkout "$(git describe --tags --abbrev=0)"
    make -j$(nproc)
    sudo make install
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

install-all() {
    install-opam
    opam install dune ocamlformat ocaml-lsp-server merlin utop

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
}

install-bootstrap() {
    # `ccache` and `mold` can make building things much faster, 
    # including the things we're about to install in `install-all`
    install-ccache
    install-mold

    unset BOOTSTRAP
    mold -run bash -x "$0"
}

if [[ ${BOOTSTRAP} ]]; then
    install-bootstrap
else
    install-all
fi
