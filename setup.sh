#!/usr/bin/env bash

set -euo pipefail

llvm_version=13
bin_dir=bin

local_path="${PWD}/${bin_dir}:${PWD}/${bin_dir}/llvm"
export PATH="${local_path}:${PATH}"

mkdir -p "${bin_dir}"

is-command() {
    command -v "$1" > /dev/null
}

link() {
    local from="${1}"
    local to="${2}"
    ln --symbolic --force "${from}" "${bin_dir}/${to}"
}

install-ccache() {
    is-command ccache || sudo apt install ccache
    ccache --max-files 0 --max-size 0
    [[ -f "${bin_dir}/ccache" ]] || link "$(which ccache)" ccache
    for compiler in cc c++ gcc g++ clang clang++; do
        ln --symbolic --force ./ccache "./${bin_dir}/${compiler}"
    done
}

install-opam() {
    is-command opam && return
    sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
    eval "$(opam env)"
}

cargo_bin="${CARGO_HOME:-${HOME}/.cargo}/bin"

install-cargo() {
    is-command cargo && return
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    export PATH="${cargo_bin}:${PATH}"
}

cargo-has() {
    local exe_name="${1}" 
    [[ -f "${cargo_bin}/${exe_name}" ]]
}

cargo-install() {
    local package_name="${1}"
    local exe_name="${2:-}"
    if [[ "${exe_name}" == "" ]]; then
        exe_name="${package_name}"
    fi
    cargo-has "${exe_name}" || (cargo-has cargo-quickinstall \
        && cargo quickinstall "${package_name}" \
        || cargo install "${package_name}" \
    )
    link "${cargo_bin}/${exe_name}" "${exe_name}"
}

install-from-opam() {
    install-opam
}

install-from-cargo() {
    install-cargo
    cargo-install cargo-quickinstall
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
    export VOLTA_HOME="${HOME}/.volta"
    export PATH="${VOLTA_HOME}/bin:${PATH}"
}

npm-install() {
    local package_name="${1}"
    local exe_name="${2:-}"
    if [[ "${exe_name}" == "" ]]; then
        exe_name="${package_name}"
    fi
    is-command "${exe_name}" || volta install "${package_name}"
    link "$(volta which "${exe_name}")" "${exe_name}"
}

install-from-npm() {
    install-volta
    volta install node@latest
    npm-install esy
}

install-llvm() {
    if is-command llvm-config; then
        local version="$(llvm-config --version)"
        if [[ "${version}" =~ ^${llvm_version}\..*$ ]]; then
            return
        fi
    fi
    sudo apt install -y lsb-release wget software-properties-common
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
    sudo ./llvm.sh "${llvm_version}"
    rm llvm.sh
    link "$(llvm-config-${llvm_version} --bindir)" "llvm"
}

install-build() {
    install-ccache &
    install-from-opam &
    install-from-npm &
    install-from-cargo &
    install-llvm &
    wait
    esy
}

install-dev-only() {
    install-from-vscode &
    wait
}

install-dev() {
    install-build &
    install-dev-only &
    wait
    just build
}

"install-${1}"
echo
echo "run this or add it to your ~/.bashrc:"
echo
echo "export PATH=\"${local_path}:\${PATH}\""
