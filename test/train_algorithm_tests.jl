using Phenology, JLD2, CSV, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, ForwardDiff, ReverseDiff, FiniteDiff, DifferentiationInterface
StationsPath = joinpath(@__DIR__, "..", "stations")

df = DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
df_n = @by(df, [:variete_cultivar_ou_provenance, :nom_du_site], :n = length(:variete_cultivar_ou_provenance))


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

param = [106.3, 6971.8]
map(x -> Pred_n([2.17, param[1], (5, 25), param[2]], x), x_vec) == map(x -> Pred_n_old([2.17, param[1], (5, 25), param[2]], x), x_vec) 


# param = [chilling_target, forcing_target] 
# Data_vec = [x_vec, n_train]
# MSE_BRIN(param, Data_vec) = sum((map(x -> Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x), Data_vec[1]) .- Data_vec[2]) .^ 2) / length(Data_vec[2])
MSE_BRIN(param, Data_vec) = sum((map(x -> Pred_n([2.17, param[1], (5, 25), param[2]], x), Data_vec[1]) .- Data_vec[2]) .^ 2) / length(Data_vec[2])
# MSE_BRIN_old(param, Data_vec) = sum((map(x -> Pred_n_old([2.17, param[1], (5, 25), param[2]], x), Data_vec[1]) .- Data_vec[2]) .^ 2) / length(Data_vec[2])

function MSE_BRIN2(param, Data_vec)
    f(x) = Pred_n([2.17, param[1], (5, 25), param[2]], x)
    return sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

function MSE_BRIN3(param, Data_vec)
    f(x) = Pred_n_old([2.17, param[1], (5, 25), param[2]], x)
    return sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

# optf = OptimizationFunction(MSE_BRIN, AutoForwardDiff())
# prob = OptimizationProblem(optf, [106.3, 6971.8], Data_vec)
# Results = Optimization.solve(prob, BFGS(), maxiters=10000)


param = [106.3, 6971.8]
Data_vec = (x_vec, n_train)
MSE_BRIN(param, Data_vec) #0

# param_vec = vcat([[[c,h] for c in 100:0.1:130] for h in 6500:1:9500]...)
f(u) = MSE_BRIN(u,Data_vec)
f2(u) = MSE_BRIN2(u,Data_vec)
f3(u) = MSE_BRIN3(u,Data_vec)

using BenchmarkTools

@btime MSE_vec = f([106.3, 6971.8])
@btime MSE_vec2 = f2([106.3, 6971.8])
@btime MSE_vec3 = f3([106.3, 6971.8])





optf = OptimizationFunction(MSE_BRIN)
prob = OptimizationProblem(optf, [150., 9000.], Data_vec)
Results = Optimization.solve(prob, NelderMead(), maxiters=1000)
Results.objective #0 : Cela signifie que sur données générées avec paramètres choisies, il est capable de trouver la sol

