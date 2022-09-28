"""
# Keynotes.jl

using Franklin and reveal.js to parse md for generating PPTs

## Levels:

1. Keynote: the whole slides
2. Page: each page of the slide (move ← and →)
3. Slide: each piece of the page (move ↑ and ↓)
4. Section: group items together, so they can be assigned to the same options
5. Items: the minimum element. Could be a mixture of [text, img, video, audio ... ]

## Options

In toml grammar, parsed from  the start of the doc, wrapped between `+++`


## Features

### Common:

- theme
- background: [color, video, gif, img ...]
- txt: [font, size ...]
- img
- autoplay
- fragmention



## Gramma:
1. use "===" for page seperator
2. use "---" for slide seperator
3. used "\g{}" for group items together, assign layout function to a group
4. use html comment gramma for controling track behaviors, and using "||" to wrap parameters:
    - eg: `<!-- | opt1:abcd, opt2:efgh | -->`
    - if opt comment comes after a md txt (item), the opt is assigned specifically to the item;
    - if opt comment comes from a new line, the opts is assigned to the smallest item the last non-comment sentence belongs to;
5.
"""
