using Phenology
using Documenter

DocMeta.setdocmeta!(Phenology, :DocTestSetup, :(using Phenology); recursive=true)

makedocs(;
    modules=[Phenology],
    authors="ArnaudG0649 <arnaudcmc@hotmail.com> and contributors",
    sitename="Phenology.jl",
    format=Documenter.HTML(;
        canonical="https://ArnaudG0649.github.io/Phenology.jl",
        edit_link="master",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/ArnaudG0649/Phenology.jl",
    devbranch="master",
)
