using Phenology, JLD2, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, ForwardDiff, ReverseDiff, FiniteDiff, DifferentiationInterface

function MSE_BRIN_L1(param, Data_vec) # param = [chilling_target, forcing_target] ; Data_vec = [x_vec, n_train, λ, θ₀]
    f(x) = @views Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x) + Data_vec[3] * sum(abs.(param .- Data_vec[4]))
    return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

doy_to_n(doy, year; CPO=(8, 1)) = doy + length(Date(year - 1, CPO[1], CPO[2]):Date(year - 1, 12, 31))

function BRIN_Model_L1(x_vec::AbstractVector, n_train::AbstractVector, λ::AbstractFloat, θ₀=(0, 0); p0=[100., 8000.])
    Data_vec = (x_vec, n_train, λ, θ₀)
    optf = OptimizationFunction(MSE_BRIN_L1, AutoForwardDiff())
    prob = OptimizationProblem(optf, p0, Data_vec, lb=[80, 5000], ub=[180, 11000])
    Results = Optimization.solve(prob, LBFGS())
    return BRIN_Model((8, 1), 2.17, Results.u[1], 5, 25, Results.u[2])
end
function BRIN_Model_L1(date_vec, x, years, doy, λ::AbstractFloat, θ₀=(0, 0); p0=[100., 8000.])
    complete_year_index = findall(year -> Date(year - 1, 8, 1):Date(year, 8, 1) ⊆ date_vec, years)
    years = years[complete_year_index]
    doy = doy[complete_year_index]
    return BRIN_Model_L1([Take_temp_year(x, date_vec, year) for year in years], doy_to_n.(doy, years), λ, θ₀; p0=p0)
end

StationsPath = joinpath(@__DIR__, "stations")
date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))

###On simulated Data

df = DataFrame(chilling_target_init=AbstractFloat[],
    forcing_target_init=AbstractFloat[],
    λ=AbstractFloat[],
    chilling_target_L1=AbstractFloat[],
    forcing_target_L1=AbstractFloat[],
    n=Integer[],
    chilling_target=AbstractFloat[],
    forcing_target=AbstractFloat[],
    site_or_true_Ct=[],
    variety_or_true_Ht=[],
    RMSE=AbstractFloat[],
    Max_Error=AbstractFloat[],
    Bias=AbstractFloat[])

function stats_error(model, x, date_vec, years, n_train)
    doy_pred = [Pred_doy(model, x, date_vec, year) for year in years]
    rmse = sqrt(sum(abs2, doy_pred - n_train) / length(n_train))
    max_error = maximum(abs.(doy_pred - n_train))
    bias = sum(doy_pred - n_train) / length(n_train)
    return rmse, max_error, bias
end


model_target = BRIN_Model(120., 7500.)
date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
date_vec, x = date_vec[1:3000], x[1:3000, :]
years = unique(year.(date_vec))
n = length(years)
complete_year_index = findall(year -> Date(year - 1, 8, 1):Date(year, 8, 1) ⊆ date_vec, years)
years = years[complete_year_index]
n_train = [Pred_doy(model_target, x, date_vec, year) for year in years]

model_classic = BRIN_Model(date_vec, x, years, n_train)
rmse, max_error, bias = stats_error(model_classic, x, date_vec, years, n_train)
push!(df, (100., 8000., 0., 0., 0., n, model_classic.chilling_target, model_classic.forcing_target, 120., 7500., rmse, max_error, bias))

model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-10)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-10, 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-2)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-2, 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 10.)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 10., 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-3)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-3, 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-10, (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-10, 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-2, (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-2, 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 10., (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 10., 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-3, (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-3, 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, 120., 7500., rmse, max_error, bias))



###On real Data
df_pheno = @subset(DataFrame(XLSX.readtable("Data_BB.xlsx", "data_Tempo")), :nom_du_site .== "INRA Domaine de Vassal", :variete_cultivar_ou_provenance .== "Sauvignon")
date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
date_vec, x = last(collect(date_vec), 10000), x[(end-9999):end,:]

years = df_pheno.annee
n_train = df_pheno.jour_de_l_annee
complete_year_index = findall(year -> Date(year - 1, 8, 1):Date(year, 8, 1) ⊆ date_vec, years)
years = years[complete_year_index]
n_train = n_train[complete_year_index]

model_classic = BRIN_Model(date_vec, x, years, n_train)
rmse, max_error, bias = stats_error(model_classic, x, date_vec, years, n_train)
push!(df, (100., 8000., 0., 0., 0., n, model_classic.chilling_target, model_classic.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))

model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-10)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-10, 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-2)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-2, 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 10.)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 10., 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-3)
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-3, 0., 0., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-10, (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-10, 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-2, (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-2, 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 10., (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 10., 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))


model_L1 = BRIN_Model_L1(date_vec, x, years, n_train, 1e-3, (110., 8500.))
rmse, max_error, bias = stats_error(model_L1, x, date_vec, years, n_train)
push!(df, (100., 8000., 1e-3, 110., 8500., n, model_L1.chilling_target, model_L1.forcing_target, "INRA Domaine de Vassal", "Sauvignon", rmse, max_error, bias))

XLSX.writetable("models_L1_results.xlsx", df)