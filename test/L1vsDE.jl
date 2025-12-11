using Phenology, JLD2, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, ForwardDiff, ReverseDiff, FiniteDiff, DifferentiationInterface

function MSE_BRIN_L1(param, Data_vec) # param = [chilling_target, forcing_target] ; Data_vec = [x_vec, n_train, λ, θ₀]
    f(x) = @views Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x) + Data_vec[3] * sum(abs.(param - Data_vec[4]))
    return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

function BRIN_Model(x_vec::AbstractVector, n_train::AbstractVector, λ::AbstractFloat, θ₀::AbstractFloat=0; p0=[100., 8000.])
    Data_vec = (x_vec, n_train, λ, θ₀)
    optf = OptimizationFunction(MSE_BRIN_L1, AutoForwardDiff())
    prob = OptimizationProblem(optf, p0, Data_vec, lb=[80, 5000], ub=[180, 11000])
    Results = Optimization.solve(prob, LBFGS())
    return BRIN_Model((8, 1), 2.17, Results.u[1], 5, 25, Results.u[2])
end
function BRIN_Model(date_vec, x, years, doy, λ::AbstractFloat, θ₀::AbstractFloat=0; p0=[100., 8000.])
    complete_year_index = findall(year -> Date(year - 1, 8, 1):Date(year, 8, 1) ⊆ date_vec, years)
    years = years[complete_year_index]
    doy = doy[complete_year_index]
    return BRIN_Model([Take_temp_year(x, date_vec, year) for year in years], doy_to_n.(doy, years), λ, θ₀; p0=p0)
end

date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))

###On simulated Data







###On real Data
