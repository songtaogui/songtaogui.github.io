@lx function sp(n)
    return "~~~$(repeat("&nbsp;", n))~~~"
end

@lx function br(n)
    return "~~~$(repeat("<br>", n))~~~"
end

@lx function randcomma(;str="")
    strs = split(str,",")
    return rand(strs)
end

@lx function crand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="cadmon sadmon-$theme">$s</span>
    """)
end

@lx function Crand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="Cadmon Sadmon-$theme">$s</span>
    """)
end

@lx function srand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="sadmon sadmon-$theme">$s</span>
    """)
end

@lx function Srand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <span class="Sadmon Sadmon-$theme">$s</span>
    """)
end

@lx function arand(s)
    themes= ["note","note","warn","info","tip","hack","error","todo"]
    theme = rand(themes)
    return html("""
    <div class="aadmon aadmon-$theme">$s</div>
    """)
end

# pattern should use C style Formatting format: %s
@lx function pout(;str="", pattern="%s")
    outstr = "~~~" * sprintf1(pattern, str) * "~~~"
    return ifelse(isempty(str), "", outstr)
end
