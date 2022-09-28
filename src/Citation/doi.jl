#=
---------------------------------
    Citation using DOI as keys
---------------------------------

## DOI based citation:

Inspired by: https://git.sr.ht/~adigitoleo/adigitoleo.srht.site/tree/main/item/utils.jl

1. get info from doi
2. output index to the dict file in the current path

---------------------------------
This is not stable, for lots of DOIs cannot be
parsed throw HTTP responses.
---------------------------------
=#

struct CiteRef
    idx::Int
    doi::AbstractString
    ref::AbstractString
end

function CiteRef(idx::AbstractString, doi::AbstractString, ref::AbstractString)
    return CiteRef(parse(Int, idx), doi, ref)
end

function doiref(doi)
    @info "Parsing $doi ..."
    url = startswith(doi, r"http(s)?://(dx\.)?doi.org/") ? doi : "https://doi.org/" * doi
    ref = "[ERROR]: NO DOI FOR $url"
    try
        response = HTTP.request("GET", url, Dict("Accept" => "text/x-bibliography"))
        ref = String(response.body)
    catch
        @error "[ERROR]: NO DOI FOR $url"
    finally
        return url,ref
    end
end

function hfun_citedoi(dois)
    refidx = Vector{String}()
    for doi in dois
        dbf = joinpath(pwd(), ".citedb")
        citedb = Dict{String, CiteRef}()
        maxidx = 0
        if isfile(dbf)
            # read dict from dbf
            open(dbf) do io
                for line in eachline(io)
                    sl = split(line, "\t")
                    @info "sl:" sl typeof(sl)
                    curciteref = CiteRef(sl[1],sl[2],sl[3])
                    push!(citedb, curciteref.doi => curciteref)
                    maxidx = curciteref.idx
                end
            end
        end
        url, ref = doiref(doi)
        if !haskey(citedb, url)
            idx = maxidx + 1
            out = join([idx, url, ref],"\t") * "\n"
            open(dbf, "a") do io
                write(io, out)
            end
        else
            idx = citedb[url].idx
        end
        # get ref idx
        push!(refidx, "<a href=\"#cite$(idx)\">$(idx)</a>")
    end
    if isempty(refidx)
        @warn "Cannot parse ref for $(dois)"
        refidx = ["ERROR",]
    end
    return """
        <span>[$(join(refidx, ","))]</span>
        """
end

function hfun_reflist()
    dbf = joinpath(pwd(), ".citedb")
    reflist = Vector{CiteRef}()
    outstr = "<h2>References</h2>"
    if isfile(dbf)
        # read dict from dbf
        open(dbf) do io
            for line in eachline(io)
                isempty(line) && continue
                sl = split(line, "\t")
                @info "Cur ref: $(sl)"
                curciteref = CiteRef(sl[1], sl[2], sl[3])
                push!(reflist, curciteref)
            end
        end
    end
    if !isempty(reflist)
        for curref in reflist
            outstr *= """
                <a id="cite$(curref.idx)">
                    <strong>$(curref.idx).</strong> $(curref.ref) <a href="$(curref.doi)">Accession</a>
                </a><br>
                """
        end
    else
        @warn "parse non ref list!"
        outstr *= """
            <a> ERROR: NO VALID REF LIST! </a>
        """
    end
    return outstr
end
