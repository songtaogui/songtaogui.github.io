"""
`\sp{N}`: N spaces in MD
"""
function lx_sp(n)
    return "~~~$(repeat("&nbsp;", n))~~~"
end


"""
`\br{N}`: N new links in MD
"""
function lx_br(n)
    return "~~~$(repeat("<br>", n))~~~"
end

"""
`\randcomma{str="a,b,c"}: random out one element of the comma seperated strings`
"""
function lx_randcomma(;str="")
    strs = split(str,",")
    return rand(strs)
end


"""
`\crand{s::Strings}`: random wrap s with pre-defined `cadmon` class color sets
"""
function lx_crand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="cadmon sadmon-$theme">$s</span>
    """)
end

"""
`\Crand{s::Strings}`: random wrap s with pre-defined `Cadmon` class color sets
"""
function lx_Crand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="Cadmon Sadmon-$theme">$s</span>
    """)
end

"""
`\srand{s::Strings}`: random wrap s with pre-defined `sadmon` class color sets
"""
function lx_srand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="sadmon sadmon-$theme">$s</span>
    """)
end

"""
`\Srand{s::Strings}`: random wrap s with pre-defined `Sadmon` class color sets
"""
function lx_Srand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="Sadmon Sadmon-$theme">$s</span>
    """)
end

"""
`\arand{s::Strings}`: random wrap s with pre-defined `aadmon` class color sets
"""
function lx_arand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <div class="aadmon aadmon-$theme">$s</div>
    """)
end

"""
`\printf{str="gst", pattern="My name is %s"}`: printf wrapper in MD
"""
function lx_printf(;str="", pattern="%s")
    # pattern should use C style Formatting format: %s
    outstr = "~~~" * sprintf1(pattern, str) * "~~~"
    return ifelse(isempty(str), "", outstr)
end
