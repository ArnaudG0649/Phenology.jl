using Optimization, OptimizationBBO

function MSE_BRIN(param, Data_vec) # param = [chilling_target, forcing_target] ; Data_vec = [x_vec, n_train]
    f(x) = @views Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x)
    return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

doy_to_n(doy, year; CPO=(8, 1)) = doy + length(Date(year - 1, CPO[1], CPO[2]):Date(year - 1, 12, 31))

function BRIN_Model(x_vec::AbstractVector, n_train::AbstractVector; p0=[100., 8000.])

    Data_vec = (x_vec, n_train) # [x_vec, n_train, λ, θ₀]
    optf = OptimizationFunction(MSE_BRIN)
    prob = OptimizationProblem(optf, p0, Data_vec, lb=[0, 0], ub=[300, 20000])
    Results = Optimization.solve(prob, BBO_adaptive_de_rand_1_bin())

    return BRIN_Model((8, 1), 2.17, Results.u[1], 5, 25, Results.u[2])
end
function BRIN_Model(date_vec, x, years, doy; p0=[100., 8000.])
    complete_year_index = findall(year -> Date(year - 1, 8, 1):Date(year, 8, 1) ⊆ date_vec, years)
    years = years[complete_year_index]
    doy = doy[complete_year_index]
    return BRIN_Model([Take_temp_year(x, date_vec, year) for year in years], doy_to_n.(doy, years); p0=p0)
end
BRIN_Model(date_vec, x, date_vecBB; p0=[100., 8000.]) = BRIN_Model(date_vec, x, year.(date_vecBB), [length(Date(year(date), 1, 1):date) for date in date_vecBB]; p0=p0)
BRIN_Model(date_vec, x, doy::AbstractVector{T}; p0=[100., 8000.]) where T<:Integer = BRIN_Model(date_vec, x, unique(year.(date_vec)), doy; p0=p0)
BRIN_Model(date_vec, x, df::DataFrame; p0=[100., 8000.]) = BRIN_Model(date_vec, x, df.annee, df.jour_de_l_annee; p0=p0)

"""
    Vine_Phenology_Pred(TN_vec::AbstractVector, TX_vec::AbstractVector, date_vec::AbstractVector{Date}, model::BRIN_Model=BRIN_Model())
    Vine_Phenology_Pred(file_TN::String, file_TX::String, model::BRIN_Model=BRIN_Model())
    Vine_Phenology_Pred(x::AbstractMatrix, date_vec, model::BRIN_Model=BRIN_Model())
    Vine_Phenology_Pred(df_TN::DataFrame, df_TX::DataFrame, model::BRIN_Model=BRIN_Model())
    Vine_Phenology_Pred(df::DataFrame, model::BRIN_Model=BRIN_Model())

From a series of TN `TN_vec`, a series of TX `TX_vec`, their dates in `date_vec` and a vine phenology model `model`, return the endodormancy break dates and budburst dates in two vectors respectively.
The temperatures and dates data can be included in two .txt file, two different dataframes or one dataframe with the two type of temperature. See [Temperatures data compatibility](@ref) for further explanation about the way to input temperatures data.
"""
function Vine_Phenology_Pred(Tn_vec::AbstractVector,
    Tx_vec::AbstractVector,
    date_vec::AbstractVector{Date},
    model::BRIN_Model=BRIN_Model())
    EB_vec = Date[]
    BB_vec = Date[]
    chilling, forcing = false, false
    sumchilling, sumforcing = 0., 0.
    for (Tn, Tx, date_, Tn1) in zip(Tn_vec[1:(end-1)], Tx_vec[1:(end-1)], date_vec[1:(end-1)], Tn_vec[2:end]) #Tn1 = TN(n+1)
        EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing = PhenoLoopStep((Tn, Tx, Tn1), date_, model, EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing)
    end
    forcing ? pop!(EB_vec) : nothing #forcing == true at the end means that it added a EB date in EB_vec which won't have it corresponding BB date in BB_vec
    return EB_vec, BB_vec
end
function Vine_Phenology_Pred(x::AbstractMatrix, date_vec, model::BRIN_Model=BRIN_Model())
    return Vine_Phenology_Pred(x[:, 1], x[:, 2], date_vec, model)
end
function Vine_Phenology_Pred(df_TN::DataFrame, df_TX::DataFrame, model::BRIN_Model=BRIN_Model())
    date_vec, x = Common_indexes([df_TN, df_TX])
    return Vine_Phenology_Pred(x, date_vec, model)
end
function Vine_Phenology_Pred(
    file_TN::String,
    file_TX::String,
    model::BRIN_Model=BRIN_Model())

    date_vec, x = Common_indexes(file_TN, file_TX)
    return Vine_Phenology_Pred(x, date_vec, model)
end
function Vine_Phenology_Pred(df::DataFrame,
    model::BRIN_Model=BRIN_Model())
    return Vine_Phenology_Pred(df.TN, df.TX, df.DATE, model)
end