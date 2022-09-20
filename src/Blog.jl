module Blog

using PlutoStaticHTML

"""
Franklin puts all HTML files inside a directory with the name "index.html".
This method unpacks that again.
"""
function unpack_html(dir)
    cd(dir) do
        dirs = filter(isdir, readdir(pwd()))
        for potential_packed_dir in dirs
            from = joinpath(potential_packed_dir, "index.html")
            to = potential_packed_dir * ".html"
            if isfile(from)
                cp(from, to; force=true)
            end
        end
    end
end

const CLONE_DIR = tempname()

"This call is required for every run because it is the place to push to."
function clone_dir()
    dir = CLONE_DIR
    if !isdir(dir)
        run(`git clone --depth=1 git@github.com:rikhuijzer/huijzer.xyz $dir`)
    end
    return dir
end

function prev_dir()
    if !("CI" in keys(ENV))
        return nothing
    end
    clone_dir()
    if get(ENV, "DISABLE_CACHE", "🍅") == "true"
        return nothing
    end
    tmpdir = tempname()
    cp(CLONE_DIR, tmpdir)
    prev_dir = joinpath(tmpdir, "public", "posts")
    unpack_html(prev_dir)
    return prev_dir
end

"""
    build(files::Union{Vector,Nothing}=nothing)
    build(file::AbstractString)

Build the notebooks. Using `files` can be useful during local development.

# Example
```
julia> Blog.build(["random-forest.jl"])
[ Info: Starting evaluation of Pluto notebook random-forest.jl
[...]
```
"""
function build(files::Union{Vector,Nothing}=nothing)
    dir = joinpath("posts", "notebooks")
    append_build_context = true
    previous_dir = prev_dir()
    # Don't try to use `franklin_output`.
    # It doesn't work nicely here because it would mean generating `.md` files
    # into posts/ and then it's hard to track which ones are generate and which ones
    # aren't for .gitignore.
    bopts = BuildOptions(dir; previous_dir)
    hopts = HTMLOptions(; append_build_context)
    if isnothing(files)
        build_notebooks(bopts, hopts)
    else
        build_notebooks(bopts, files, hopts)
    end
    return nothing
end
build(file::AbstractString) = build([string(file)])

"Some files at the top level like the README.md"
function add_root_files(pages_dir)
    readme = """
        # Monorepo for huijzer.xyz

        Files in this repository are pushed here from the following places:

        - `public/Books.jl`: https://github.com/rikhuijzer/Books.jl
        - `public/DiscountedCashFlows.jl`: https://github.com/rikhuijzer/DiscountedCashFlows.jl
        - `public/PlutoStaticHTML.jl`: https://github.com/rikhuijzer/PlutoStaticHTML.jl
        - `public/PowerAnalyses.jl`: https://github.com/rikhuijzer/PowerAnalyses.jl
        - `public/StableTrees.jl`: https://github.com/rikhuijzer/StableTrees.jl
        - `public/ds`: https://github.com/rikhuijzer/ds
        - `/` and `/public/`: https://gitlab.com/rikh/blog

        The run from `blog` will also remove the history and re-generate this README and sitemaps.
        """
    write(joinpath(pages_dir, "README.md"), readme)
    l = "LICENSE.md"
    cp(joinpath(pkgdir(Blog), l), joinpath(pages_dir, l); force=true)
    return nothing
end

filter_urlset_end!(collection::Vector{<:AbstractString}) = filter!(!=("</urlset>"), collection)

"Merge sitemaps from different sites."
function merge_sitemaps(pages_dir)
    blog_sitemap_path = joinpath(pages_dir, "public", "sitemap.xml")
    ds_sitemap_path = joinpath(pages_dir, "public", "ds", "sitemap.xml")
    if isfile(blog_sitemap_path) && isfile(ds_sitemap_path)
        sep = '\n'

        blog_sitemap_without_footer = let
            text = read(blog_sitemap_path, String)
            lines = split(text, sep)
            filter_urlset_end!(lines)
            join(lines[1:end-1], sep)
        end

        ds_sitemap_without_header = let
            text = read(ds_sitemap_path, String)
            lines = split(text, sep)
            filter_urlset_end!(lines)
            join(lines[3:end], sep)
        end

        updated_sitemap = string(blog_sitemap_without_footer, '\n', ds_sitemap_without_header, "</urlset>")
        println()
        print(updated_sitemap)
        println()
        write(blog_sitemap_path, updated_sitemap)

        return nothing
    else
        @warn "One or more sitemap files not found"
    end
    return nothing
end

"Add a redirect from blog/inference to blogs/inference."
function add_juliacon_redirect(pages_dir::String)
    html = raw"""
        <!--This file is added from src/Blog.jl. -->
        <meta http-equiv="refresh" content="0; url=/posts/inference/"/>
        """
    post_dir = joinpath(pages_dir, "public", "post")
    mkpath(post_dir)
    path = joinpath(post_dir, "inference.html")
    write(path, html)
    return path
end

function deploy()
    if !("CI" in keys(ENV))
        error("Don't run this locally. It will mess up the Git config.")
    end

    run(`git config --global user.email "rikhuijzer@pm.me"`)
    run(`git config --global user.name "rikhuijzer"`)

    # An extra clone call since the tempname changes between different Julia invocations.
    # Better would be to move the multiple Julia steps into one step, but well this works
    # too.
    clone_dir()

    pages_dir = CLONE_DIR
    cd(pages_dir) do
        run(`git branch -m main old`)
        run(`git checkout --orphan main`)
    end

    # Cleanup.
    names = readdir(joinpath(pages_dir, "public"); join=false)
    exceptions = [
        "ds",
        "Books.jl",
        "DiscountedCashFlows.jl",
        "PlutoStaticHTML.jl",
        "PowerAnalyses.jl",
        "StableTrees.jl"
    ]
    for name in names
        if !(name in exceptions)
            path = joinpath(pages_dir, "public", name)
            println("Removing $path")
            rm(path; recursive=true)
        end
    end

    # Copy all the files generated by Franklin and leave the rest untouched.
    names = readdir("__site"; join=false)
    for name in names
        from = joinpath("__site", name)
        to = joinpath(pages_dir, "public", name)
        cp(from, to)
    end

    add_root_files(pages_dir)
    merge_sitemaps(pages_dir)
    add_juliacon_redirect(pages_dir)

    cd(pages_dir) do
        run(`git add .`)
        run(`git commit -m 'Deploy from gitlab.com/rikh/blog'`)
        run(`git push --force origin main`)
    end
    return nothing
end

end # module

