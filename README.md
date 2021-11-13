# C*

Also written as `cstar` and pronounced **Sea Star**.


![A sea star (aka starfish)](https://www.papo-france.com/1266-thickbox_default/starfish.jpg =100x100)


## Proposal
See the [proposal](./proposal.md) for an overview of the language.

## Language Reference Manual
See the [language reference manual](./LRM.md) for a detailed reference manual for the language.

## Building
Run `./setup.sh <mode>`, where `mode` is either `build` or `dev`.  
Run `export PATH="${PWD}/bin:${PWD}/bin/llvm:${PATH}"`.  
Then run `just build` to build and 
install `cstar` to your `$PATH`, i.e, to `./bin/cstar`.  
To add shell autocompletions, run `eval "$(cstar completions)"`.
