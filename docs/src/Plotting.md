```@meta
CurrentModule = Phenology
```
## Plots with CairoMakie

Before calling one of these functions you must load [CairoMakie.jl](https://docs.makie.org/stable/explanations/backends/cairomakie.html) with 
```julia
using CairoMakie
```

### Plot series of endodormancy break and budburst Dates

```@docs
Phenology.Plot_Pheno_Dates_EB_BB(::Vector{Dates.Date},::Vector{Dates.Date},::Any)
Phenology.Plot_Pheno_Dates_EB_BB(::Any,::Any,::Any)
```

```@docs
PlotHistogram
```

### Plot Freezing Risk

```@docs
Plot_Freeze_Risk
Plot_Freeze_Risk_sample
Plot_Freeze_Risk_Bar
```

