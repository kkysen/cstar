set shell := ["bash", "-c"]

just_dir := justfile_directory()
cwd := invocation_directory()

export PATH := just_dir + "/bin:" + just_dir + "/bin/llvm:" + env_var("PATH")

default:
    just --list

install-opam:
    bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)"
    opam init

# install tools needed/nice for development
setup what:
    ./setup.sh {{what}}

path: (setup "path")

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
        return s === "" ? "''" : s.includes(" ") ? `"${s}"` : s;
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
    #!/usr/bin/env bash
    set -euxo pipefail
    cd "{{invocation_directory()}}"
    strace -etrace=execve -f --string-limit 10000 -qq --output strace.$PPID.out {{args}} || true
    just filter-exec < strace.$PPID.out
    rm strace.$PPID.out

# run dune, but through mold
dune *args:
    esy build dune {{args}}

esy-path path:
    fd \
        --type directory \
        --exact-depth 1 \
        '^cstar-.*$' \
        _esy/default/store/b \
        --exec-batch exa --sort modified \
        "{{join("{}/default/src", path)}}" \
        | tail -n 1

link-cstar:
    ln -s -f "../$(just esy-path "cstar.exe")" ./bin/cstar

build *args: (dune "build" "./src/cstar.exe" args) link-cstar

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

watch *args: (dune "build" "--watch" args)

alias w := watch

watch-and-run cmd:
    watchexec 'just build && {{cmd}}'

alias wr := watch-and-run

add +dependencies:
    esy add $(printf "@opam/%s " {{dependencies}})

repl dir="src": (dune "utop" dir)

pp-path path: (esy-path replace(path, ".ml", ".pp.ml"))

do-expand path:
    #!/usr/bin/env bash
    set -euox pipefail

    src_path="$(just esy-path "{{path}}")"
    pp_path="${src_path/.ml/.pp.ml}"
    ppx_path="${src_path/.ml/.ppx.ml}"
    if [[ "${pp_path}" -nt "${ppx_path}" ]]; then
        esy ocamlc -stop-after parsing -dsource "${pp_path}" >& "${ppx_path}"
        touch --reference "${pp_path}" "${ppx_path}"
    fi
    echo "${ppx_path}"

expand path:
    bat "$(just do-expand "{{path}}")"

watch-parser:
    watchexec --watch src/parser.mly 'esy ocamlyacc -v src/parser.mly && echo success!'

clean-parser:
    rm -f src/parser.{ml,mli,output}

generate-code-listing-generic source_paths_path output_markdown_path file_types_path:
    #!/usr/bin/env node
    const fsp = require("fs/promises");
    const pathLib = require("path");

    // https://github.com/fitzgen/glob-to-regexp
    function globToRegex(glob, {
        extended = false,
        globstar = false,
        flags = "",
    }) {
        let regex = "";
        let inGroup = false;
        for (let i = 0; i < glob.length; i++) {
            const c = glob[i];
            switch (c) {
                case "/":
                case "$":
                case "^":
                case "+":
                case ".":
                case "(":
                case ")":
                case "=":
                case "!":
                case "|":
                    regex += "\\" + c;
                    break;
                // all fallthroughs if not extended
                case "?":
                    if (extended) {
                        regex += ".";
                        break;
                    }
                case "[":
                case "]":
                    if (extended) {
                        regex += c;
                        break;
                    }
                case "{":
                    if (extended) {
                        inGroup = true;
                        regex += "(";
                        break;
                    }
                case "}":
                    if (extended) {
                        inGroup = false;
                        regex += ")";
                        break;
                    }
                case ",":
                    if (inGroup) {
                        regex += "|";
                        break;
                    }
                    regex += "\\" + c;
                    break;
                case "*":
                    const prev = glob[i - 1];
                    let starCount = 1;
                    while (glob[i + 1] === "*") {
                        starCount++;
                        i++;
                    }
                    const next = glob[i + 1];
                    if (!globstar) {
                        regex += ".*";
                    } else {
                        const isGlobstar = starCount > 1
                            && (prev === "/" || prev === undefined)
                            && (next === "/" || next === undefined);
                        if (isGlobstar) {
                            regex += "((?:[^/]*(?:\/|$))*)";
                            i++;
                        } else {
                            regex += "([^/]*)";;
                        }
                    }
                    break;
                default:
                    regex += c;
                    break;
                }
        }

        if (!flags || !~flags.indexOf("g")) {
            regex = "^" + regex + "$";
        }

        return new RegExp(regex, flags);
    }

    async function readFileTypes(fileTypesPath) {
        const fileTypes = (await fsp.readFile(fileTypesPath))
            .toString()
            .split("\n")
            .filter(Boolean)
            .map(line => {
                const [fileType, globsStr] = line.split(": ", 2);
                const globs = globsStr
                    .split(", ")
                    .map(glob => {
                        const regex = globToRegex(glob, {
                            extended: true, 
                            globstar: true,
                        });
                        return {glob, regex};
                    });
                const test = (s) => {
                    // fileType === "ocaml" && console.log({s, globs});
                    return globs.some(glob => glob.regex.test(s));
                };
                return {
                    fileType,
                    globs,
                    test,
                };
            })
            ;
        const detect = (path) => {
            const fileName = pathLib.basename(path);
            // console.log({path});
            return fileTypes
                .find(e => e.test(fileName))
                .fileType
                ;
        };
        return {fileTypes, detect};
    }

    async function readSources(pathsPath) {
        const s = (await fsp.readFile(pathsPath)).toString();
        const paths = (s.includes("\0") 
            ? s.split("\0")
            : s.split("\n")
        ).filter(Boolean);
        return await Promise.all(
            paths.map(async path => {
                const src = (await fsp.readFile(path)).toString();
                return {path, src};
            })
        );
    }

    function markdownHeaderToHtmlId(header) {
        return [...header]
            .map(c => {
                if (/[a-zA-Z0-9-]/.test(c)) {
                    return c;
                } else if (/\s/.test(c)) {
                    return "-";
                } else {
                    return "";
                }
            })
            .join("")
            .toLowerCase()
            ;
    }

    const tableOfContentsName = "Code Listing - Table of Contents";
    const tableOfContentsId = markdownHeaderToHtmlId(tableOfContentsName);

    function generateSourceMarkdown({src, fileTypes}) {
        const tick = "`";
        const ticks = "```";
        const fileType = fileTypes.detect(src.path);
        return [
            `### ${tick}${src.path}${tick}`,
            `${ticks} ${fileType}`,
            src.src,
            `${ticks}`,
            `[${tableOfContentsName}](#${tableOfContentsId})`,
        ].join("\n");
    }

    function generateMarkdownTableOfContents(sources) {
        const paths = sources.map(e => e.path);
        return [
            `## ${tableOfContentsName}`,
            ...paths.map(path => {
                const tick = "`";
                const id = markdownHeaderToHtmlId(path);
                return `* [${tick}${path}${tick}](#${id})`;
            })
        ].join("\n");
    }

    async function generateMarkdownCodeListing({
        sourcePathsPath, 
        fileTypesPath, 
        outputMarkdownPath,
    }) {
        const fileTypes = await readFileTypes(fileTypesPath);
        const sources = await readSources(sourcePathsPath);
        const markdown = [
            `# Code Listing`,
            generateMarkdownTableOfContents(sources),
            ...sources
                .map(src => generateSourceMarkdown({src, fileTypes}))
        ]
            .join("\n\n")
            ;
        await fsp.writeFile(outputMarkdownPath, markdown);
    }

    async function main() {
        await generateMarkdownCodeListing({
            sourcePathsPath: "{{source_paths_path}}", 
            outputMarkdownPath: "{{output_markdown_path}}", 
            fileTypesPath: "{{file_types_path}}",
        });
    }

    main().catch(e => {
        console.error(e);
        process.exit(1);
    })

generate-code-listing:
    just generate-code-listing-generic \
        <(fd '\.ml(|i|l|y)' src -0) \
        report/code-listing.md \
        <(rg --type-list)

generate-git-log:
    echo "# Project Timeline / Git Log" > report/git-log.md
    echo '' >> report/git-log.md
    echo '```log' >> report/git-log.md
    git log --stat >> report/git-log.md
    echo '```' >> report/git-log.md


generate-report-docs:
    rm -rf report
    cp -r docs report

generate-report-markdown:
    cd report && bat \
        proposal.md \
        LRM.md \
        git-log.md \
        code-listing.md \
        > cstar.md

generate-report-pdf:
    @rg 'WSL2' /proc/version --quiet \
        && echo "mdpdf uses a headless chromium and doesn't work under WSL2, try WSL1" \
        && exit 1
    cd report && \
        rg --files --type markdown \
        | xargs --max-args 1 mdpdf

generate-report-archive:
    git archive \
        --format zip \
        --output report/cstar.zip \
        --prefix "$(basename -s .git "$(git remote get-url origin)")/" \
        $(git branch --show-current)

generate-report: generate-report-docs generate-code-listing generate-git-log generate-report-markdown generate-report-archive generate-report-pdf
