using Phenology, JLD2, CSV, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, ForwardDiff
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

# param = [chilling_target, forcing_target] 
# Data_vec = [x_vec, n_train]
# MSE_BRIN(param, Data_vec) = sum((map(x -> Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x), Data_vec[1]) .- Data_vec[2]) .^ 2) / length(Data_vec[2])
MSE_BRIN(param, Data_vec) = sum((map(x -> Pred_n([2.17, param[1], (5, 25), param[2]], x), Data_vec[1]) .- Data_vec[2]) .^ 2) / length(Data_vec[2])

param = [106.3, 6971.8]
Data_vec = (x_vec, n_train)
MSE_BRIN(param, Data_vec) |> sqrt
# algo=NelderMead()

optf = OptimizationFunction(MSE_BRIN, AutoForwardDiff())
prob = OptimizationProblem(optf, [106., 8000.], Data_vec)
Results = Optimization.solve(prob, LBFGS(), maxiters=1000000)


#Second new function Pred_n

date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
x_2020, date_vec_2020 = Take_temp_year(x, date_vec, 2020), date_vec[Iyear_CPO(date_vec, 2020, CPO=(8, 1))]

function Pred_n_no_loop(model::AbstractVector, x::AbstractMatrix)
    C_units = cumsum(map(T -> Rc(T, model[1]), eachrow([x_2020[1:(end-1), :] x_2020[2:end, 1]])))
    EB = findfirst(C_units .> model[2])
    H_units = cumsum(map(T -> Rf(T, model[3]), eachrow([x_2020[1:(end-1), :] x_2020[2:end, 1]]))[EB:end])
    return findfirst(H_units .> model[4]) + EB - 1
end
function Pred_n_no_loop(model::BRIN_Model, x::AbstractMatrix)
    C_units = cumsum(map(T -> Rc(T, model), eachrow([x_2020[1:(end-1), :] x_2020[2:end, 1]])))
    EB = findfirst(C_units .> model.chilling_target)
    H_units = cumsum(map(T -> Rf(T, model), eachrow([x_2020[1:(end-1), :] x_2020[2:end, 1]]))[EB:end])
    return findfirst(H_units .> model.forcing_target) + EB - 1
end

model = [2.17, 119.0, (8.19, 25.), 13236]

using BenchmarkTools

@btime Pred_n(model, x_2020)
@btime Pred_n_no_loop(model, x_2020)
@btime Pred_n_no_loop(BRIN_Model(), x_2020)




MSE_BRIN(param, Data_vec) = sum((map(x -> Pred_n([2.17, param[1], (5, 25), param[2]], x), Data_vec[1]) .- Data_vec[2]) .^ 2) / length(Data_vec[2])

param = [106.3, 6971.8]
Data_vec = (x_vec, n_train)
MSE_BRIN(param, Data_vec) |> sqrt
# algo=NelderMead()

optf = OptimizationFunction(MSE_BRIN, AutoForwardDiff())
prob = OptimizationProblem(optf, [106., 8000.], Data_vec)
Results = Optimization.solve(prob, LBFGS(), maxiters=1000000)