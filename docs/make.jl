using HierarchicalTemporalMemory
using Documenter

DocMeta.setdocmeta!(HierarchicalTemporalMemory, :DocTestSetup, :(
    using HierarchicalTemporalMemory;
    const HTM=HierarchicalTemporalMemory
  ); recursive=true)

makedocs(;
    modules=[HierarchicalTemporalMemory],
    authors="Konstantinos Samaras-Tsakiris <ksamtsak@gmail.com> and contributors",
    repo="https://github.com/oblynx/HierarchicalTemporalMemory.jl/blob/{commit}{path}#L{line}",
    sitename="HierarchicalTemporalMemory.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://oblynx.github.io/HierarchicalTemporalMemory.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/oblynx/HierarchicalTemporalMemory.jl",
)
