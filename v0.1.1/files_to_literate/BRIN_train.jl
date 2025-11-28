# stations_folder = join("stations")#hide
# nothing#hide
# md"""
# ```@meta
# CurrentModule = Phenology
# ```

# ## Training BRIN models

# With this module you can fit BRIN models on temperatures data and registered phenological dates as training set : 
# """
# using Phenology
# #TN (daily minimal) and TX (daily maximal) temperatures in Montpellier, from 1946 to 2022.
# date_vec, x = Common_indexes(joinpath(stations_folder, "TN_Montpellier.txt"), joinpath(stations_folder, "TX_Montpellier.txt"))

# #Bud burst dates of Chasselas variety registered at the Domaine de Vassal (43.327676, 3.565170) 
# df_vassal_chasselas = @chain begin
#     DataFrame(XLSX.readtable(joinpath(@__DIR__, "..","..","..", "Data_BB.xlsx"), "data_Tempo"))
#     @subset(:variete_cultivar_ou_provenance .== "Chasselas")
#     @subset(:nom_du_site .== "INRA Domaine de Vassal")
# end
# date_vecBB = Date.(df_vassal_chasselas.date)

# #Fitting model
# model = BRIN_Model(date_vec, x, date_vecBB)
# md"""
# You can also put the years and the days of the year `doy` in the example as an `integer` (the number of days between the 1ˢᵗ of January and the date) of the bud burst in two separate vectors : 
# """
# years = df_vassal_chasselas.annee
# doy = df_vassal_chasselas.jour_de_l_annee
# model = BRIN_Model(date_vec, x, years, doy)
# md"""
# The method `BRIN_Model(x_vec::AbstractVector, n_train::AbstractVector)` takes as arguments two vectors of same length, which each index is associated to a year :
#  - `x_vec` includes in each index a series of yearly temperatures between the 1ˢᵗ of August of the precedent year and 30ᵗʰ of July of the current year.
#  - `n_train` includes in each index the number of day between the 1ˢᵗ of August of the precedent year and the bud burst date.

# Example : 
# """
# n_train = [doy[i] + length(Date(year - 1, 8, 1):Date(year - 1, 12, 31)) for (i,year) in enumerate(years)] #doy + nb of days between 1ˢᵗ of August and the last day of the year
# x_vec = [x[Date(year - 1, 8, 1) .<= date_vec .< Date(year, 8, 1), :] for year in years]
# model = BRIN_Model(x_vec, n_train)

# using Literate

# Literate.markdown(joinpath(@__DIR__, "BRIN_train.jl"), joinpath(@__DIR__), mdstrings=true)