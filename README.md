# mdtoweb
_mdtoweb_ is a tool to create a static web page from Markdown source files. It comes with an option to customize the resulting HTML output via a configuration file. This makes it possible to apply custom CSS styles or use wire in an existing framework like Bootstrap.

## Example
```
$ git clone git@github.com:pecimuth/mdtoweb.git
$ cd mdtoweb
$ ./mdtoweb.sh examples/src examples/build
$ firefox examples/build/index.html
```
The script traverses the `examples/src` directory tree and translates all of the Markdown files into correspondig html files in `examples/build`. `examples/src/config.cfg` loads the Bootstrap framework and adds some styling to the webpage.

### Translate on modication
Use the `--watch` flag to wait for changes in the source subtree and translate modified files.
```
$ ./mdtoweb.sh --watch examples/src examples/build
```

## Configuration
Configuration file must be named `config.cfg` and placed in the source root directory. The configs are then used for all other source files in the subtree. 
The expected format is `key=value`. In case of html tag options, the values are parsed as follows: `tagName[.class1[.class2[...]]]` results in HTML tag `<tagName class="class1 class2 ...">content</tagName>`.

### Configuration options
List of all options with their respective default values:

```
# html tag options
paragraph=p
heading-1=h1
heading-2=h2
heading-3=h3
heading-4=h4
heading-5=h5
heading-6=h6
unordered-list=ul
ordered-list=ol
quote=blockquote
list-item=li
link=a
image=img
bold=strong
italic=em
monospace=code
title-tag=title
link-tag=link
page-wrapper=
# page options
title=
link-stylesheet-href=
link-stylesheet-integrity=
link-stylesheet-crossorigin=
```

## Usage

### Syntax
`mdtoweb.sh [options] sourceDirectory buildDirectory`

### Options
`-h, --help`    Print help and quit.
`-f, --force`   Overwrite the ouput files. By default, only modified files are overwritten. Modified files are considered source files which are newer than their corresponding HTML files.
`-w, --watch`   Wait for changes and continuously translate modifed source files.

### Positional arguments
`sourceDirectory` is a path to the root of the source subtree. Optionaly may contain a configuration file, which must be named `config.cfg`. The whole subtree is traversed and all files with the `.md` suffix are translated into HTML files.
`buildDirectory` is path to a directory where the HTML files should be placed. The structure of the source directory is preserved. If some directory doesn't exist, it is created.
