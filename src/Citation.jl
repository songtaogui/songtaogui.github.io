#=
Make Citation smoothly in My Franklin Blog
=#

#=
## Local bib db based citation:

1. parse all local bib, with citekey as key
2. get only first three authors
3. add urls to title
4. use (author et al., year) format citeindex
5. sort bibliography alphabetically
=#

function loadbib(db::String)
    # check = :error :warn :none
    return BibParser.parse_file(db, :BibTeX; check=:none)
end

# const CITEDB = loadbib(CITEDBFILE)
const CITEDB = loadbib("_assets/citedb/ref.bib")

function fmtidx(idx::String, name::String; format="normal")
    if !haskey(CITEDB, idx)
        @error "No ref information in the database for $k"
        name = "ERROR"
    end

    return """<a href="#$idx">$(name)</a>"""
end

function hfun_citebib(ks)
    rpath = Franklin.FD_ENV[:CUR_PATH]
    idxpath = replace(rpath, r"\.md$" => ".citedb")
    indexes = Vector{Any}()
    if isfile(idxpath)
        indexes = unique(readlines(idxpath))
    end
    open(idxpath, "a") do io
        for k in ks
            # @info "Parse citation $k for $rpath ..."
            curbib = CITEDB[k]
            curbib_year = curbib.date.year
            curbib_first_author = curbib.authors |> first
            curbib_etal = length(curbib.authors) > 1 ? " et al. " : " "
            outname = curbib_first_author.last * curbib_etal * curbib_year
            if !(k in indexes)
                write(io, "$(k)\n")
                curidx = fmtidx(k, outname)
                push!(indexes, curidx)
            end
        end
    end
    final_index = join(indexes, ", ")
    return """
        <span>
            ($final_index)
        </span>
        """
end

function fmtreflist(idx::String)
    refstr = ""

    if !haskey(CITEDB, idx)
        @error "No ref information in the database for $k"
        refstr = "ERROR: No ref information in the database for $k"
    else
        curbib = CITEDB[idx]
        curbib_year = curbib.date.year
        etal = " et al. "
        if length(curbib.authors) < 3
            etal = " "
        end
        f3a_str = join([x.last * " " * x.first for x in first(curbib.authors,3)], ", ")
        curbib_first_three_authors = f3a_str * etal
        curbib_pubinfo = join(filter(!isempty,["<span style=\"color:#9970AB\"><i>" * curbib.in.journal * "</i></span>", curbib.in.pages, curbib.in.volume]),", ")
        curbib_title = replace(curbib.title, r"[\{\}]" => "")
        if !isempty(curbib.access.doi)
            url = startswith(curbib.access.doi, r"http(s)?://(dx\.)?doi.org/") ? curbib.access.doi : "https://doi.org/" * curbib.access.doi
            curbib_title = """<a href="$(url)" target="_blank">$(curbib_title)</a>"""
        else
            curbib_title = """<a><span style="color:#08519C">$(curbib_title)</span></a>"""
        end
        refstr = """
            <span>$(curbib_first_three_authors) ($(curbib_year)). $(curbib_title). $(curbib_pubinfo)</span>
            """
    end

    return """
        <li id="$(idx)">
            $refstr
        </li>
        """
end

function hfun_citebiblist()
    rpath = Franklin.FD_ENV[:CUR_PATH]
    idxpath = replace(rpath, r"\.md$" => ".citedb")
    reflist = "<h2>References</h2>"

    if !isfile(idxpath)
        @error "No indexes found in $idxpath !"
        reflist *= """
            <span style="color:#A50026">ERROR</span>
            """
        return reflist
    end

    for curidx in unique(readlines(idxpath))
        reflist *= fmtreflist(curidx)
    end

    return reflist
end # func hfun_citebiblist
a = ["a", "b", "c"]
