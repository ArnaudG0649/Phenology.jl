using ConcreteStructs

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
    BRIN_Model(date_vec, x, date_vecBB::AbstractVector{Date}; p0=[100., 8000.])
    BRIN_Model(date_vec, x, years, doy; p0=[100., 8000.])
    BRIN_Model(x_vec::AbstractVector, n_train::AbstractVector; p0=[100., 8000.])


Structure which contains the parameters for a phenelogical BRIN model for grapevine. The default values are the ones suggested in [garcia_de_cortazar-atauri_performance_2009](@cite) (table 5 p 323).
With the three last methods you can initiate a BRIN_Model by fitting on temperatures, dates et bud burst dates data (see [Training BRIN models](@ref)). It is done with a differential evolution optimization algorithm.
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
