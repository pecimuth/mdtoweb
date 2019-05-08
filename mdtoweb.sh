#!/bin/bash

src=""
dst=""

config=""
verbose=""
force=""
watch=""

maybeTranslateFile() {
    translated="n"

    if [ "$force" = "y" -o "$1" -nt "$2" ]; then
        if [ "$config" = "" ]; then
            ./translate.awk "$1" > "$2"
            translated="y"
        else
            ./translate.awk "$config" "$1" > "$2"
            translated="y"
        fi
    fi

    if [ "$verbose" = "y" -a "$translated" = "y" ]; then
        echo "Translated $1 > $2"
    fi
}

watchLoop() {
    verbose="y"
    while true; do
        traverseTree
        sleep 1
    done
}

traverseTree() {
    q="$src"

    while [ ! "$q" = "" ]; do
        elem=$(echo "$q" | sed -n '1p')
        q=$(echo "$q" | sed -n '2,$p')
        if [ "$elem" = "" ]; then
            continue
        fi
        for file in "$elem"/*; do
            if [ -d "$file" ]; then
                q=$(echo -e "$q\n$file")
            elif (echo "$file" | grep -Eq "\.md$"); then
                dirName=$(echo "$file" | sed -e "s=$src\(.*\)/[^/]*=$dst\1=")
                if [ ! -d "$dirName" ]; then
                    mkdir "$dirName"
                fi
                newFile=$(echo "$file" | sed -e "s=$src\(.*\)md$=$dst\1html=")
                maybeTranslateFile "$file" "$newFile"
            fi
        done
    done
}

printHelp() {
echo "
mdtoweb.sh [options] sourceDirectory buildDirectory

OPTIONS
-h, --help    Print help and quit.
-f, --force   Overwrite the ouput files.
-w, --watch   Wait for changes and continuously translate modifed source files. 

POSITIONAL ARGUMENTS
sourceDirectory     Path to the root of the source subtree.
buildDirectory      Path to a directory where the html files should be placed.

Examples of usage:  mdtoweb.sh examples/src examples/build
                    mdtoweb.sh --watch examples/src examples/build
"
}

while [ $# -gt 0 ]; do
    case "$1" in
    --help|-h)
        printHelp
        exit
        ;;
    --watch|-w)
        watch="y"
        shift
        ;;
    --force|-f)
        force="y"
        shift
        ;;
    *)
        if [ $# -eq 2 ]; then
            src="$1"
            dst="$2"
            shift 2
        else
            printHelp
            exit 1
        fi
        ;;
    esac
done

if [ "$src" = "" ]; then
    printHelp
    exit 1
fi

if [ -r "$src/config.cfg" ]; then
    config="$src/config.cfg"
fi

if [ "$watch" = "y" ]; then
    watchLoop
else
    traverseTree
fi
