#!/bin/awk -f

function getTagFromDesc(desc) {
    if(match(desc, "^[^.]*")) {
        return substr(desc, RSTART, RLENGTH)
    }
    return ""
}

function getClassFromDesc(desc) {
    if(match(desc, "\\..+")) {
        classes = substr(desc, RSTART + 1, RLENGTH)
        gsub("\\.", " ", classes)        
        return classes
    }
    return ""
}

function openingTag(elementType, otherAttrs) {
    class = getClassFromDesc(elemDesc[elementType])
    if (class) {
        attr = " class=\"" class "\""
    } else {
        attr = ""
    }
    for (attrKey in otherAttrs) {
        attr = attr " " attrKey "=\"" otherAttrs[attrKey] "\""
    }
    return "<" getTagFromDesc(elemDesc[elementType]) attr ">"
}

function closingTag(elementType) {
    return "</" getTagFromDesc(elemDesc[elementType]) ">"
}

function makeImages() {
    while (match(blockInnerContent, "!\\[[^]]+\\]\\(.+\\)")) {
        prefix = substr(blockInnerContent, 1, RSTART - 1)
        link = substr(blockInnerContent, RSTART, RLENGTH)
        suffix = substr(blockInnerContent, RSTART + RLENGTH)
        match(link, "^!\\[[^]]+\\]")
        imgAttr["alt"] = substr(link, 3, RLENGTH - 3)
        imgAttr["src"] = substr(link, RLENGTH + 2, length(link) - RLENGTH - 2)
        blockInnerContent = prefix openingTag("image", imgAttr) suffix
    }
}

function makeLinks() {
    while (match(blockInnerContent, "\\[[^]]+\\]\\(.+\\)")) {
        prefix = substr(blockInnerContent, 1, RSTART - 1)
        link = substr(blockInnerContent, RSTART, RLENGTH)
        suffix = substr(blockInnerContent, RSTART + RLENGTH)
        match(link, "^\\[[^]]+\\]")
        anchorText = substr(link, 2, RLENGTH - 2)
        anchorAttr["href"] = substr(link, RLENGTH + 2, length(link) - RLENGTH - 2)
        blockInnerContent = prefix openingTag("link", anchorAttr) anchorText closingTag("link") suffix
    }
}

function makeTextAttributes() {
    makeTextAttribute("\\*\\*", "**", "bold")
    makeTextAttribute("_", "_", "italic")
    makeTextAttribute("`", "`", "monospace")
}

function makeTextAttribute(needle, notNeedle, elementType) {
    while (match(blockInnerContent, needle "[^" notNeedle "]+" needle)) {
        prefix = substr(blockInnerContent, 1, RSTART - 1)
        content = substr(blockInnerContent, RSTART + length(notNeedle), RLENGTH - 2 * length(notNeedle))
        suffix = substr(blockInnerContent, RSTART + RLENGTH)
        blockInnerContent = prefix openingTag(elementType) content closingTag(elementType) suffix
    }
}

function finalizeContentBlock() {
    if (!blockInnerContent && blockElementType == "paragraph") {
        return
    }
    makeTextAttributes()
    makeImages()
    makeLinks()
    blockContent = openingTag(blockElementType) "\n" blockInnerContent closingTag(blockElementType) "\n"
    outputBlock[++blockCounter] = blockContent
    blockInnerContent = ""
    blockElementType = "paragraph"
    nextOrderedListNbr = 1
}

function min(valA, valB) {
    if (valA < valB)
        return valA;
    return valB;
}

function arrayKeyExists(key, arr) {
    for (arrKey in arr) {
        if (arrKey == key) {
            return 1
        }
    }
    return 0
}

BEGIN {
    blockCounter = 0
    nextOrderedListNbr = 1
    blockElementType = "paragraph" # p|h|ul|ol|q
    blockInnerContent = ""
    elemDesc["paragraph"] = "p"
    elemDesc["heading-1"] = "h1"
    elemDesc["heading-2"] = "h2"
    elemDesc["heading-3"] = "h3"
    elemDesc["heading-4"] = "h4"
    elemDesc["heading-5"] = "h5"
    elemDesc["heading-6"] = "h6"
    elemDesc["unordered-list"] = "ul"
    elemDesc["ordered-list"] = "ol"
    elemDesc["quote"] = "blockquote"
    elemDesc["list-item"] = "li"
    elemDesc["link"] = "a"
    elemDesc["image"] = "img"
    elemDesc["bold"] = "strong"
    elemDesc["italic"] = "em"
    elemDesc["monospace"] = "code"
    elemDesc["title-tag"] = "title"
    elemDesc["link-tag"] = "link"
    elemDesc["page-wrapper"] = ""
    conf["title"] = ""
    conf["link-stylesheet-href"] = ""
    conf["link-stylesheet-integrity"] = ""
    conf["link-stylesheet-crossorigin"] = ""
    FS = "="
}

match(FILENAME, "config\\.cfg$") && NF > 1 {
    if (arrayKeyExists($1, elemDesc) == 1) {
        elemDesc[$1] = substr($0, length($1) + 2)
    } else if (arrayKeyExists($1, conf) == 1) {
        conf[$1] = substr($0, length($1) + 2)
    } else {
        print "Unknown property '" $1 "' on line " NF "." > "/dev/tty"
        exit
    }
    next
}

match(FILENAME, "config\\.cfg$") && ($0 == "" || match($0, "^#")) {
    next
}

match(FILENAME, "config\\.cfg$") {
    print "Error reading " FILENAME " on line " NR "." > "/dev/tty"
    exit
}

/^$/ {
    finalizeContentBlock()
    next
}

match($0, "^#+") {
    finalizeContentBlock()
    blockElementType = "heading-" min(RLENGTH, 6)
    gsub("^#+", "")
    blockInnerContent = $0 "\n"
    finalizeContentBlock()
    next
}

match($0, "^ *\\* ") && blockElementType != "unordered-list"  {
    finalizeContentBlock()
    blockElementType = "unordered-list"
    gsub("^ *\\* ", "")
    blockInnerContent = openingTag("list-item") "\n" $0 "\n" closingTag("list-item") "\n"
    next
}

match($0, "^ *\\* ") && blockElementType == "unordered-list"  {
    gsub("^ *\\* ", "")
    blockInnerContent = blockInnerContent openingTag("list-item") "\n" $0 "\n" closingTag("list-item") "\n"
    next
}

match($0, "^ *" nextOrderedListNbr "\\.") && blockElementType != "ordered-list"  {
    finalizeContentBlock()
    blockElementType = "ordered-list"
    gsub("^ *" nextOrderedListNbr "\\.", "")
    blockInnerContent = openingTag("list-item") "\n" $0 "\n" closingTag("list-item") "\n"
    ++nextOrderedListNbr
    next
}

match($0, "^ *" nextOrderedListNbr "\\.") && blockElementType == "ordered-list"  {
    gsub("^ *" nextOrderedListNbr "\\.", "")
    blockInnerContent = blockInnerContent openingTag("list-item") "\n" $0 "\n" closingTag("list-item") "\n"
    ++nextOrderedListNbr
    next
}

/^=+$/ {
    nbrLines = split(blockInnerContent, lines, "\n")
    headingLine = lines[nbrLines - 1]
    blockInnerContent = substr(blockInnerContent, 1, length(blockInnerContent) - length(headingLine) - 1)
    finalizeContentBlock()
    gsub("^=+", "", headingLine)
    blockInnerContent = headingLine "\n"
    blockElementType = "heading-1"
    finalizeContentBlock()
    next
}

/^>/ {
    finalizeContentBlock()
    blockElementType = "quote"
    gsub("^>", "")
    blockInnerContent = $0 "\n"
    finalizeContentBlock()
    next
}

/---+/ {
    finalizeContentBlock()
    outputBlock[++blockCounter] = "<hr />\n"
    finalizeContentBlock()
    next
}

/  $/ {
    blockInnerContent = blockInnerContent $0 "<br />\n"
    next
}

{
    blockInnerContent = blockInnerContent $0 "\n"
}

END {
    finalizeContentBlock()

    print "<!DOCTYPE html>\n<html>\n<head>\n"
    
    if (conf["title"] != "") {
        print openingTag("title-tag") conf["title"] closingTag("title-tag") "\n"
    }

    if (conf["link-stylesheet-href"] != "") {
        stylesheetAttr["rel"] = "stylesheet"
        stylesheetAttr["href"] = conf["link-stylesheet-href"]
        if (conf["link-stylesheet-integrity"] != "") {
            stylesheetAttr["integriy"] = conf["link-stylesheet-integrity"]
        }
        if (conf["link-stylesheet-crossorigin"] != "") {
            stylesheetAttr["crossorigin"] = conf["link-stylesheet-crossorigin"]
        }
        print openingTag("link-tag", stylesheetAttr) "\n"
    }
    
    print "</head>\n<body>"
    
    if (elemDesc["page-wrapper"] != "") {
        print openingTag("page-wrapper")
    }

    for (i = 1; i <= blockCounter; ++i) {
        print outputBlock[i]
    }

    if (elemDesc["page-wrapper"] != "") {
        print closingTag("page-wrapper")
    }

    print "</body>\n</html>"
}
