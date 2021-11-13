set shell := ["bash", "-c"]

default:
    just --list

install-opam:
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
    opam init

# install tools needed/nice for development
setup what:
    ./setup.sh {{what}}

filter-exec:
    #!/usr/bin/env node
    const fs = require("fs");
    const pathLib = require("path");

    const which = (() => {
        const cache = new Map();
        const paths = process.env.PATH.split(pathLib.delimiter);
        return program => {
            if (cache.has(program)) {
                return cache.get(program);
            }
            for (const dir of paths) {
                const path = pathLib.join(dir, program);
                let found = false;
                try {
                    fs.accessSync(path, fs.constants.X_OK);
                    found = true;
                } catch {}
                if (found) {
                    cache.set(program, path);
                    return path;
                }
            }
            cache.set(program, undefined);
            return undefined;
        };
    })();

    const colors = {
        reset: 0,
        bright: 1,
        dim: 2,
        underscore: 4,
        blink: 5,
        reverse: 7,
        hidden: 8,
        fg: {
            black: 30,
            red: 31,
            green: 32,
            yellow: 33,
            blue: 34,
            magenta: 35,
            cyan: 36,
            white: 37,
        },
        bg: {
            black: 40,
            red: 41,
            green: 42,
            yellow: 43,
            blue: 44,
            magenta: 45,
            cyan: 46,
            white: 47,
        },
    };

    function ansiColorSequence(colorCode) {
        return `\x1b[${colorCode}m`;
    }

    const color = !process.stdout.isTTY ? ((colorCode, s) => s) : (colorCode, s) => {
        if (colorCode === undefined) {
            throw new Error("undefined color");
        }
        return ansiColorSequence(colorCode) + s + ansiColorSequence(colors.reset);
    };

    function quote(s) {
        return s.includes(" ") ? `"${s}"` : s;
    }

    function colorPath(path, dirColor, nameColor) {
        const {dir, base} = pathLib.parse(path);
        return (dir ? color(dirColor, dir + pathLib.sep) : "") + color(nameColor, base);
    }

    const output = fs.readFileSync("/dev/stdin")
        .toString()
        .split("\n")
        .map(s => {
            const match = /execve\(([^)]*)\) = 0/.exec(s);
            if (!match) {
                return;
            }
            const [_, argsStr] = match;
            const args = argsStr.replaceAll(/\[|\]/g, "").split(", ");
            return args
                .map(rawArgs => {
                    if (!(rawArgs.endsWith('"') && rawArgs.endsWith('"'))) {
                        return;
                    }
                    const arg = rawArgs.slice('"'.length, -'"'.length);
                    return arg;
                })
                .filter(Boolean);
        })
        .filter(Boolean)
        .map(([path, argv0, ...argv]) => {
            const program = pathLib.basename(path);
            const isInPath = which(program) === path;
            return {
                path: isInPath ? program : path,
                argv0: (argv0 === path || argv0 === program) ? undefined : argv0,
                argv,
            };
        }).map(({path, argv0, argv}) => ({
            path: quote(path),
            argv0: argv0 === undefined ? undefined : quote(argv0),
            argv: argv.map(quote),
        })).map(({path, argv0, argv}) => {
            if (argv0 === undefined) {
                return [
                    colorPath(path, colors.fg.yellow, colors.fg.green), 
                    ...argv,
                ];
            } else {
                return [
                    "[" + colorPath(path, colors.fg.yellow, colors.fg.blue) + "]", 
                    colorPath(argv0, colors.fg.yellow, colors.fg.green), 
                    ...argv,
                ];
            }
        })
        .map(args => args.join(" "))
        .join("\n") + "\n";
    fs.writeFileSync("/dev/stdout", output);

trace-exec *args:
    -strace -etrace=execve -f --string-limit 10000 -qq --output strace.$PPID.out {{args}}
    just filter-exec < strace.$PPID.out
    rm strace.$PPID.out

# run dune, but through mold
dune *args:
    dune {{args}}

build *args: (dune "build" "./src/cstar.exe" args)

alias b := build

run *args: (dune "exec" "./src/cstar.exe" args)

alias r := run

fmt-diff *args: (dune "build" "@fmt" args)

fmt *args: (fmt-diff "--auto-promote" args)

test *args: (dune "test" args)

alias t := test

clean *args: (dune "clean" args)
    rm -rf esy.lock _esy/ node_modules/

alias c := clean
