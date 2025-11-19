using Phenology, JLD2, CSV, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, OptimizationBBO
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

x_vec = BRIN_Montpellier_Take_temp_year.(years)
date_vecs = BRIN_Montpellier_date_vec_year.(years)
n_train = df_vassal_chasselas.jour_de_l_annee .+ length(Date(2019, 8, 1):Date(2019, 12, 31))

[length(Date(year - 1, 8, 1):Vine_Phenology_Pred(x, date_vec)[2][1]) for (year, x, date_vec) in zip(years, x_vec, date_vecs)] == map(x -> Pred_n2(BRIN_Model(), x), x_vec)

# param = [chilling_target, forcing_target] 
# Data_vec = [x_vec, n_train]

function MSE_BRIN(param, Data_vec)
    f(x) = @views Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x)
    return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

# function MSE_BRIN2(param, Data_vec)
#     f(x) = @views Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x)
#     return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
# end

# function MSE_BRIN3(model, Data_vec)
#     f(x) = @views Pred_n(model, x)
#     return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
# end

# BRIN_Model((8, 1), 2.17, 2., 5, 25, 4.)
# BRIN_Model()

# function BRIN_Model(c, h)
#     return BRIN_Model((8, 1), 2.17, c, 5, 25, h)
# end

#{typeof((8, 1)),typeof(2.17),typeof(c),typeof(5),typeof(25),typeof(h)}

param = [106.3, 6971.8]
Data_vec = (x_vec, n_train)


f(u) = MSE_BRIN(u, Data_vec)
# f2(u) = MSE_BRIN2(u, Data_vec)
# f3(u) = MSE_BRIN3(u, Data_vec)

# using BenchmarkTools

# @btime MSE_vec = f([106.3, 6971.8])
# @btime MSE_vec2 = f2([106.3, 6971.8])
# @btime MSE_vec3 = f3(BRIN_Model(106.3, 6971.8))

# param_vec = vcat([[[c, h] for c in 100:0.2:130] for h in 6500:2:9500]...)
# save("MSE_vec.jld2", "MSE_vec", MSE_vec, "param_vec", param_vec)

# param_vec[argmin(MSE_vec)] # = [122.6, 6570.]

optf = OptimizationFunction(MSE_BRIN)
prob = OptimizationProblem(optf, [110, 7000.], Data_vec, lb=[80, 5000], ub=[180, 11000])
Results = Optimization.solve(prob, BBO_adaptive_de_rand_1_bin())

