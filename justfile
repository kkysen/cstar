set shell := ["bash", "-c"]

default:
    just --list

install-opam:
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
    opam init

# install tools needed/nice for development
install-tooling:
    BOOTSTRAP=1 bash -x install-tooling.sh

# run dune, but through mold
dune *args:
    mold -run dune {{args}}

build *args: (dune "build" "./src/cstar.exe" args)

alias b := build

run *args: (dune "exec" "./src/cstar.exe" args)

alias r := run

fmt-diff *args: (dune "build" "@fmt" args)

fmt *args: (fmt-diff "--auto-promote" args)
