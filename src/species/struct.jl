using ConcreteStructs, Optimization, OptimizationBBO

function MSE_BRIN(param, Data_vec) # param = [chilling_target, forcing_target] ; Data_vec = [x_vec, n_train]
    f(x) = @views Pred_n(BRIN_Model((8, 1), 2.17, param[1], 5, 25, param[2]), x)
    return @views sum(abs2, f.(Data_vec[1]) - Data_vec[2]) / length(Data_vec[2])
end

doy_to_n(doy, year; CPO=(8, 1)) = doy + length(Date(year - 1, CPO[1], CPO[2]):Date(year - 1, 12, 31))
"""
    AppleModel(CPO::Tuple{Integer,Integer}=(10, 30),
        chilling_model::AbstractAction=TriangularAction(1.1, 20.),
        chilling_target::AbstractFloat=56.0,
        forcing_model::AbstractAction=ExponentialAction(9.0),
        forcing_target::AbstractFloat=83.58)

Structure which contains the parameters for a phenelogical apple model. The default values are the ones suggested in [legave_comprehensive_2013](@cite) (F1 Gold 1).
"""
@concrete struct AppleModel
    CPO
    chilling_model
    chilling_target
    forcing_model
    forcing_target
    AppleModel(CPO::Tuple{Integer,Integer}=(10, 30),
        chilling_model::AbstractAction=TriangularAction(1.1, 20.),
        chilling_target::AbstractFloat=56.0,
        forcing_model::AbstractAction=ExponentialAction(9.0),
        forcing_target::AbstractFloat=83.58) = new{typeof(CPO),typeof(chilling_model),typeof(chilling_target),typeof(forcing_model),typeof(forcing_target)}(CPO, chilling_model, chilling_target, forcing_model, forcing_target)
end

"""
    BRIN_Model(CPO::Tuple{Integer,Integer}=(8, 1),
        Q10::AbstractFloat=2.17,
        chilling_target::AbstractFloat=119.0,
        T0Bc::AbstractFloat=8.19,
        TMBc::AbstractFloat=25.,
        forcing_target::AbstractFloat=13236)

Structure which contains the parameters for a phenelogical BRIN model for grapevine. The default values are the ones suggested in [garcia_de_cortazar-atauri_performance_2009](@cite).
"""
@concrete struct BRIN_Model
    CPO
    Q10
    chilling_target #Cc
    T0Bc
    TMBc
    forcing_target #Ghc
    BRIN_Model(CPO::Tuple{Integer,Integer}=(8, 1),
        Q10::AbstractFloat=2.17,
        chilling_target::AbstractFloat=119.0,
        T0Bc::AbstractFloat=8.19,
        TMBc::AbstractFloat=25.,
        forcing_target::AbstractFloat=13236) = new{typeof(CPO),typeof(Q10),typeof(chilling_target),typeof(T0Bc),typeof(TMBc),typeof(forcing_target)}(CPO, Q10, chilling_target, T0Bc, TMBc, forcing_target)
end
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
BRIN_Model(date_vec, x, doy; p0=[100., 8000.]) = BRIN_Model(date_vec, x, unique(year.(date_vec)), doy; p0=p0)
