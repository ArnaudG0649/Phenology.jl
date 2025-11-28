stations_folder = join("stations")#hide
nothing#hide
md"""
```@meta
CurrentModule = Phenology
```

# Phenology.jl

Welcome to the documentation for [Phenology.jl](https://github.com/ArnaudG0649/Phenology.jl) ! 
With this package you can predict the phenology (budburst and endo dormancy break) of apple and grapevine from temperatures data.
The models used are the ones presented in [legave_comprehensive_2013](@citet) for apple (F1 Gold 1) and in [garcia_de_cortazar-atauri_performance_2009](@citet) for grapevine (BRIN model).


## Tutorial

### Data extraction

First, we need a file with the temperatures data and their dates. This package is adapted to use some type of txt.file from the [ECA&D](https://www.ecad.eu/dailydata/predefinedseries.php) database and the portal [DRIAS *Les futurs du climat*](https://www.drias-climat.fr/) as it is explained in the section [Temperatures data compatibility](@ref)
The data files examples used in this tutorial are available in the `station` folder on the github repository of the package.
As you will see further, the functions to predict phenological dates can take as arguments the data file path but if you want to extract the data in a dataframe you can use the function [`Phenology.extract_series`](@ref) :  
"""
using Phenology
#average daily temperatures in Montpellier
df_TG_Montpellier = extract_series(joinpath(stations_folder, "TG_Montpellier.txt"))
first(df_TG_Montpellier, 10)
md"""
### Apple Phenology

To predict apple dormancy break and budburst dates, just call the function [`Apple_Phenology_Pred`](@ref) on daily average temperatures data : 
"""
A_EB_Montpellier, A_BB_Montpellier = Apple_Phenology_Pred(df_TG_Montpellier.TG, df_TG_Montpellier.DATE)
first(A_BB_Montpellier, 5) #The budburst dates of the 5 first years.
md"""
Note that `Apple_Phenology_Pred(df_TG_Montpellier)` and `Apple_Phenology_Pred(joinpath("stations", "TG_Montpellier.txt"))` return the same output. 

### Grapevine Phenology

To predict grapevine dormancy break and budburst dates, call the function [`Vine_Phenology_Pred`](@ref) on daily minimal and maximal temperatures data : 

"""
G_EB_Montpellier, G_BB_Montpellier = Vine_Phenology_Pred(joinpath(stations_folder, "TN_Montpellier.txt"), joinpath(stations_folder, "TX_Montpellier.txt"))
first(G_BB_Montpellier, 5)
md"""
Like the apple function, calling the other methods with dataframes or vectors return the same results (see [`Vine_Phenology_Pred`](@ref)).

### Freezing Risk

You can also predict the risk of freezing after budburst with the functions [`FreezingRisk`](@ref) and [`FreezingRiskMatrix`](@ref), based on minimal daily temperatures, their dates and the budburst dates :
"""
df_TN_Bonn = extract_series(joinpath(stations_folder, "TN_Bonn.txt"))
A_EB_Bonn, A_BB_Bonn = Apple_Phenology_Pred(joinpath(stations_folder, "TG_Bonn.txt"))
nothing#hide
# - For example we predict the freezing risk after the fourth apple budburst in 1981 : 
FreezingRisk(df_TN_Bonn, A_BB_Bonn[4])
# - Or after all apple budburst : 
FreezingRiskMatrix(df_TN_Bonn, A_BB_Bonn)
md"""

### Plots with [CairoMakie](https://docs.makie.org/stable/explanations/backends/cairomakie.html) extension.

If you have the package [CairoMakie.jl](https://docs.makie.org/stable/explanations/backends/cairomakie.html) loaded, you can use multiple plot functions, showed in [Plots with CairoMakie](@ref) section.
For example you can plot the annual phenological dates from predictions on multiple sites : 
"""
using CairoMakie

A_EB_Nantes, A_BB_Nantes = Apple_Phenology_Pred(joinpath(stations_folder, "TG_Nantes.txt"))

colors = ["blue", "orange", "green"]
label = ["Montpellier", "Bonn", "Nantes"]
Plot_Pheno_Dates_EB_BB([A_EB_Montpellier, A_EB_Bonn, A_EB_Nantes],
    [A_BB_Montpellier, A_BB_Bonn, A_BB_Nantes],
    (10, 30),
    EB_label=label,
    BB_label=label,
    EB_colors=colors,
    BB_colors=colors
)
md"""
Or the freezing risks : 
"""
Plot_Freeze_Risk_Bar(df_TN_Bonn, A_BB_Bonn,
    color="orange",
    label="Bonn")
md"""
## References

```@bibliography
```

"""