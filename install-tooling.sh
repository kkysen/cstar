#!/usr/bin/env bash

set -e

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

install-mold-ld() {
    install-mold
    local mold_path="$(which mold)"
    local mold_parent_dir="$(dirname "${mold_path}")"
    local mold_dir="${mold_parent_dir}/mold-ld"
    local mold_ld_path="${mold_dir}/ld"
    [[ -x "$mold_ld_path" ]] && return
    [[ -d "$mold_dir" ]] || test -w "$mold_parent_dir" && mkdir "$mold_dir" || sudo mkdir "$mold_dir"
    [[ -f "$mold_ld_path" ]] || test -w "$mold_dir" && ln --symbolic "$mold_path" "$mold_ld_path" || sudo ln --symbolic "$mold_path" "$mold_ld_path"
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
    # this is the slowest command
    opam install dune ocamlformat ocamlformat-rpc ocaml-lsp-server merlin utop
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
}

install-from-vscode() {
    is-command code || return
    code --install-extension ocamllabs.ocaml-platform
}

install-all() {
    install-from-opam &
    install-from-cargo &
    install-from-vscode &
    wait
}

install-bootstrap() {
    # `ccache` and `mold` can make building things much faster, 
    # including the things we're about to install in `install-all`
    install-ccache
    install-mold
    install-mold-ld

    unset BOOTSTRAP
    mold -run bash "$0"
}

if [[ ${BOOTSTRAP} ]]; then
    install-bootstrap
else
    install-all
fi
