# cd(@__DIR__)
# import Pkg
# Pkg.activate(".")

using Phenology, CairoMakie
using Documenter, DocumenterCitations, Literate
import .Remotes

Literate.markdown(joinpath(@__DIR__, "src", "index", "index.jl"), joinpath(@__DIR__, "src"), mdstrings=true)

bib = CitationBibliography(joinpath(@__DIR__, "refs.bib");
    style=:authoryear #:numeric  # default
)

DocMeta.setdocmeta!(Phenology, :DocTestSetup, :(using Phenology); recursive=true)

makedocs(;
    modules=[Phenology, isdefined(Base, :get_extension) ?
                        Base.get_extension(Phenology, :CairoMakieExt) :
                        Phenology.CairoMakieExt],
    authors="ArnaudG0649 <arnaudcmc@hotmail.com> and contributors",
    sitename="Phenology.jl",
    format=Documenter.HTML(;
        prettyurls=true,
        repolink="https://github.com/ArnaudG0649/Phenology.jl",
        canonical="https://ArnaudG0649.github.io/Phenology.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Phenological models for each species" => "species.md",
        "Freezing Risk" => "freezing_risk.md",
        "Plot extension with CairoMakie" => "Plotting.md",
        "Temperatures data compatibility" => "Temp_data.md",
    ],
    # remotes=nothing,
    plugins=[bib],
    workdir=joinpath(@__DIR__,".."),
    # repo = Remotes.GitHub("ArnaudG0649","https://github.com/ArnaudG0649/Phenology.jl"),
    checkdocs=:none
)

# deploydocs(;
#     devbranch = "master",
#     repo="github.com/ArnaudG0649/Phenology.jl",
# )

using LiveServer; # BE CAREFUL TO REMOVE/PUT IN COMMENTS WHEN PUSHING
serve(dir="docs/build");