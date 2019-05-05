#!/bin/awk -f

function getTagFromDesc(desc) {
    if(match(desc, "^[^.]*")) {
        return substr(desc, RSTART, RLENGTH)
    }
    return "div"
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
        blockInnerContent = prefix openingTag("img", imgAttr) suffix
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
        blockInnerContent = prefix openingTag("a", anchorAttr) anchorText closingTag("a") suffix
    }
}


function finalizeContentBlock() {
    if (!blockInnerContent && blockElementType == "p") {
        return
    }
    makeImages()
    makeLinks()
    blockContent = openingTag(blockElementType) "\n" blockInnerContent closingTag(blockElementType) "\n"
    outputBlock[++blockCounter] = blockContent
    blockInnerContent = ""
    blockElementType = "p"
    nextOrderedListNbr = 1
}

BEGIN {
    blockCounter = 0
    nextOrderedListNbr = 1
    blockElementType = "p" # p|h|ul|ol|q
    blockInnerContent = ""
    elemDesc["p"] = "p"
    elemDesc["h"] = "h1"
    elemDesc["ul"] = "ul"
    elemDesc["ol"] = "ol"
    elemDesc["q"] = "blockquote"
    elemDesc["li"] = "li"
    elemDesc["a"] = "a"
    elemDesc["img"] = "img"
}

/^$/ {
    finalizeContentBlock()
    next
}

match($0, "^#+") {
    finalizeContentBlock()
    blockElementType = "h"
    gsub("^#+", "")
    blockInnerContent = $0 "\n"
    finalizeContentBlock()
    next
}

match($0, "^ *\\* ") && blockElementType != "ul"  {
    finalizeContentBlock()
    blockElementType = "ul"
    gsub("^ *\\* ", "")
    blockInnerContent = openingTag("li") "\n" $0 "\n" closingTag("li") "\n"
    next
}

match($0, "^ *\\* ") && blockElementType == "ul"  {
    gsub("^ *\\* ", "")
    blockInnerContent = blockInnerContent openingTag("li") "\n" $0 "\n" closingTag("li") "\n"
    next
}

match($0, "^ *" nextOrderedListNbr "\\.") && blockElementType != "ol"  {
    finalizeContentBlock()
    blockElementType = "ol"
    gsub("^ *" nextOrderedListNbr "\\.", "")
    blockInnerContent = openingTag("li") "\n" $0 "\n" closingTag("li") "\n"
    ++nextOrderedListNbr
    next
}

match($0, "^ *" nextOrderedListNbr "\\.") && blockElementType == "ol"  {
    gsub("^ *" nextOrderedListNbr "\\.", "")
    blockInnerContent = blockInnerContent openingTag("li") "\n" $0 "\n" closingTag("li") "\n"
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
    blockElementType = "h"
    finalizeContentBlock()
    next
}

/^>/ {
    finalizeContentBlock()
    blockElementType = "q"
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
    for (i = 1; i <= blockCounter; ++i) {
        print outputBlock[i]
    }
}
