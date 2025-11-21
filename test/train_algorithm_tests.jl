using Phenology, JLD2, CSV, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, OptimizationBBO, ForwardDiff
StationsPath = joinpath(@__DIR__, "..", "stations")

df = DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
df_n = @by(df, [:variete_cultivar_ou_provenance], :n = length(:variete_cultivar_ou_provenance))


df_vassal_chasselas = @chain begin
    DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
    @subset(:variete_cultivar_ou_provenance .== "Chasselas")
    @subset(:nom_du_site .== "INRA Domaine de Vassal")
end

#Making the training set
date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
BRIN_Montpellier_Take_temp_year(year) = Take_temp_year(x, date_vec, year, CPO=(8, 1))
BRIN_Montpellier_date_vec_year(year) = date_vec[Iyear_CPO(date_vec, year, CPO=(8, 1))]
years = df_vassal_chasselas.annee
doy = df_vassal_chasselas.jour_de_l_annee

#doy for "day of the year" = "jour_de_l_annee"
doy_to_n(doy, year; CPO=(8, 1)) = doy + length(Date(year - 1, CPO[1], CPO[2]):Date(year - 1, 12, 31))

x_vec = BRIN_Montpellier_Take_temp_year.(years)
# date_vecs = BRIN_Montpellier_date_vec_year.(years)
n_train = doy_to_n.(df_vassal_chasselas.jour_de_l_annee, years)

# param = [chilling_target, forcing_target] 
# Data_vec = [x_vec, n_train]

function MSE_BRIN(param, Data_vec) # param = [chilling_target, forcing_target] ; Data_vec = [x_vec, n_train]
    f(x) = @views Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x)
    return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

# f(u) = MSE_BRIN(u, Data_vec)

# Data_vec = (x_vec, n_train) # [x_vec, n_train, λ, θ₀]
# optf = OptimizationFunction(MSE_BRIN)
# prob = OptimizationProblem(optf, [100., 8000.], Data_vec, lb=[80, 5000], ub=[180, 11000])
# Results = Optimization.solve(prob, BBO_adaptive_de_rand_1_bin())

# using CairoMakie

# fig, ax, plt = lines(years, n_train, label="Rec Data")
# plt2 = lines!(ax, years, [Pred_n(BRIN_Model((8, 1), 2.17, Results.u[1], 5, 25, Results.u[2]), x) for x in x_vec], label="Pred Data")
# axislegend(ax)
# fig


years = unique(year.(date_vec))
complete_year_index = findall(year -> Date(year - 1, 8, 1):Date(year, 8, 1) ⊆ date_vec, years)
years = years[complete_year_index]
x_vec = [Take_temp_year(x, date_vec, year) for year in years]
model_target = BRIN_Model((8, 1), 2.17, 111., 5, 25, 6578.3)
n_train = [Pred_n(model_target, x) for x in x_vec]
# model = BRIN_Model(date_vec, x, years, n_train .- length(Date(0, 8, 1):Date(0, 12, 31)))
# n_pred = [Pred_n(model, x) for x in x_vec]

for h in -100:100
    model = BRIN_Model((8, 1), 2.17, 111., 5, 25, 6578.3 + h)
    n_pred = [Pred_n(model, x) for x in x_vec]
    Δ = abs.(n_train .- n_pred)

    println(h," S. rate :",sum(Δ .== 0) / length(Δ) )
    println(unique(n_train .- n_pred),"\n") #<=1 pour condition 
end

model = BRIN_Model((8, 1), 2.17, 111., 5, 25, 6578.3 + 20)
n_pred = [Pred_n(model, x) for x in x_vec]
Δ = abs.(n_train .- n_pred)
println(unique(Δ),"\n")
sum(Δ .== 0) / length(Δ)  

