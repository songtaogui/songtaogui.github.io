#=
pluto related functions
=#


# #   hfun_plutohtml(com)
# # Embed a Pluto notebook via:
# # https://github.com/rikhuijzer/PlutoStaticHTML.jl
# function hfun_plutohtml(com)
#     # file = string(Franklin.content(com.braces[1]))::String
#     file = string(com[1])
#     dir = "pluto/"
#     html_path = dir * file * ".html"
#     jl_path = dir * file * ".jl"
#     return """
#     {{ insert ../$html_path }}
#     <p>_To run this blog post locally, open <a href="/$jl_path">this notebook</a> with Pluto.jl._</p>
#     """
# end
