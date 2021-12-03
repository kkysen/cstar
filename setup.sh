#!/usr/bin/env bash

set -euo pipefail

if [[ "${debug:-}" != "" ]]; then
    set -x
fi

llvm_version=13
bin_dir=bin

local_path="${PWD}/${bin_dir}:${PWD}/${bin_dir}/llvm"
export PATH="${local_path}:${PATH}"

mkdir -p "${bin_dir}"

is-command() {
    local command="${1}"
    [[ "${command}" != "" ]] && command -v "${command}" > /dev/null
}

link() {
    local from="${1}"
    local to="${2}"
    # macos `ln` doesn't support full flag names like `--symbolic --force`
    ln -s -f "${from}" "${bin_dir}/${to}"
}

link-on-path() {
    local exe_name="${1}"
    [[ -x "${bin_dir}/${exe_name}" ]] && return
    link "$(which "${exe_name}")" "${exe_name}"
}

cached-install() {
    local install_func="${1}"
    local package_name="${2}"
    local exe_name="${3:-}"
    local exe_dir="${exe_dir:-}"
    local which_prefix="${which_prefix:-}"
    if [[ "${exe_name}" == "" ]]; then
        exe_name="${package_name}"
    fi
    if ! is-command "${exe_name}"; then
        "${install_func}" "${package_name}" "${exe_name}"
    fi
    if [[ "${exe_dir:-}" == "" ]]; then
        local exe_path=$(${which_prefix} which "${exe_name}")
    else
        local exe_path="${exe_dir}/${exe_name}"
    fi
    link "${exe_path}" "${exe_name}"
}

if is-command brew; then
    link-on-path brew
    package_installer=("brew")
elif is-command apt; then
    link-on-path apt
    package_installer=("sudo" "apt")
else
    echo >&2 "can't find `brew` or `apt`"
    exit 1
fi

package-install-raw() {
    "${package_installer[@]}" install -y "${1}"
}

package-install() {
    cached-install package-install-raw "${@}"
}

install-ccache() {
    is-command ccache || package-install ccache
    [[ -f "${bin_dir}/ccache" ]] || link-on-path ccache
    ccache --max-files 0 --max-size 0
    for compiler in cc c++ gcc g++ clang clang++; do
        link ./ccache "${compiler}"
    done
}

install-opam-raw() {
    package-install curl
    sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)
    eval "$(opam env)"
}

install-opam() {
    is-command opam || install-opam-raw
    link-on-path opam
}

cargo_bin="${CARGO_HOME:-${HOME}/.cargo}/bin"

install-cargo-raw() {
    package-install curl
    curl https://sh.rustup.rs -sSf | sh
    export PATH="${cargo_bin}:${PATH}"
}

install-cargo() {
    is-command cargo || install-cargo-raw
    link-on-path cargo
}

cargo-has() {
    local exe_name="${1}" 
    [[ -f "${cargo_bin}/${exe_name}" ]]
}

cargo-install-raw() {
    local package_name="${1}"
    local exe_name="${2}"
    cargo-has "${exe_name}" || (cargo-has cargo-quickinstall \
        && cargo quickinstall "${package_name}" \
        || cargo install "${package_name}" \
    )
}

cargo-install() {
    exe_dir="${cargo_bin}" cached-install cargo-install-raw "${@}"
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
    cargo-install bat
    cargo-install exa
    cargo-install gitui
    cargo-install git-delta delta
    cargo-install tokei
    cargo-install skim sk
    cargo-install hyperfine
}

vscode-extension-install() {
    local name="${1}"
    local num_found=$(fd \
        -uu \
        --type directory \
        --exact-depth 1 \
        --fixed-strings "${name}" \
        ~/.vscode-server/extensions/ \
        | wc -l)
    if [[ ${num_found} -gt 0 ]]; then
        return
    fi
    code --install-extension "${name}"
}

install-from-vscode() {
    is-command code || return
    link-on-path code
    vscode-extension-install ocamllabs.ocaml-platform
    vscode-extension-install skellock.just
}

install-volta-raw() {
    package-install curl
    curl https://get.volta.sh | bash
    export VOLTA_HOME="${HOME}/.volta"
    export PATH="${VOLTA_HOME}/bin:${PATH}"
}

install-volta() {
    is-command volta || install-volta-raw
    link-on-path volta
}

npm-install-raw() {
    local package_name="${1}"
    volta install "${package_name}"
}

npm-install() {
    which_prefix=volta cached-install npm-install-raw "${@}"
}

install-from-npm() {
    install-volta
    npm-install node@latest node
    npm-install esy
}

install-llvm() {
    if is-command llvm-config; then
        local version="$(llvm-config --version)"
        if [[ "${version}" =~ ^${llvm_version}\..*$ ]]; then
            return
        fi
    fi
    case "${OSTYPE}" in
        linux*)
            package-install lsb-release lsb_release
            package-install wget
            package-install software-properties-common ""
            wget https://apt.llvm.org/llvm.sh
            chmod +x llvm.sh
            sudo ./llvm.sh "${llvm_version}"
            rm llvm.sh
            local llvm_config_suffix="-${llvm_version}"
            ;;
        darwin*)
            brew install "llvm@${llvm_version}" || brew reinstall llvm
            local llvm_config_suffix=""
            ;;
        *)
            echo >&2 "unsupported platform: ${OSTYPE}"
            return 1
            ;;
    esac
    link "$(llvm-config${llvm_config_suffix} --bindir)" "llvm"
}

install-in-parallel() {
    local pids=()
    for func in "${@}"; do
        "${func}" &
        pids+=($!)
    done
    local i=0
    for pid in ${pids[@]}; do
        wait ${pid}
        local status=$?
        i=$((i + 1))
        if [[ ${status} -ne 0 ]]; then
            echo kill ${pids[@]:i}
            kill ${pids[@]:i}
            return ${status}
        fi
    done
}

install-build-deps() {
    install-ccache
    install-from-opam
    install-from-npm
    install-from-cargo
}

patch-esy-llvm() {
    fd --full-path 'llvm.*install.sh$' ~/.esy/source/ \
        --exec patch --input patches/llvm-install.sh.patch --unified --backup --forward \
        || true # allow error from already applied patch
}

esy-install() {
    esy install || (path-esy-llvm && esy install)
    esy
}

install-build() {
    install-build-deps
    esy-install
}

install-dev-only() {
    install-from-vscode
}

install-dev-deps() {
    install-build-deps
    package-install inotify-tools inotifywait
    install-from-vscode
}

install-dev() {
    install-dev-deps
    esy-install
    just build
}

install-path() {
    echo "export PATH=\""\${PWD}/${bin_dir}:\${PWD}/${bin_dir}/llvm":\${PATH}\""
    exit 0
}

"install-${1}"
echo
echo "run this or add it to your ~/.bashrc:"
echo
install-path
