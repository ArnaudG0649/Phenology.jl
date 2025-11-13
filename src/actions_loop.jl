Iyear_CPO(date::AbstractVector{Date}, year::Integer; CPO=(8, 1)) = Date(year - 1, CPO[1], CPO[2]) .<= date .< Date(year, CPO[1], CPO[2]) - Day(1)

Take_temp_year(x::AbstractVector, date_vec, year; CPO=(8, 1)) = x[Iyear_CPO(date_vec, year, CPO=CPO)]
Take_temp_year(x::AbstractMatrix, date_vec, year; CPO=(8, 1)) = x[Iyear_CPO(date_vec, year, CPO=CPO), :]
Take_temp_year(df, year; multiple=false, CPO=(8, 1)) = multiple ? Take_temp_year(df[:, [:TN, :TX]], df.DATE, year, CPO=CPO) : Take_temp_year(df[:, 2], df.DATE, year; CPO=CPO)

# Apple and BRIN (grapevine) phenology model parameters

# DScine a generic AbstractAction abstract type
"""
# Example for chilling model
    chill_model = LinearAction(10.0, 5.0)  # Th = 10, Sc = 5
    T = 7.0
    Rc(T, chill_model)  # Should return (10 - 7) / 5 = 0.6

# Example for forcing model
    force_model = SigmoidalAction(15.0, 3.0)  # Th = 15, Sc = 3
    T = 18.0
    Rf(T, force_model)  # Should return a value based on the sigmoidal equation
"""
abstract type AbstractAction end

## Concrete types for models with their parameters

struct BinaryAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
end

struct LinearAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct ExponentialAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
end

struct SigmoidalAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct TriangularAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct ParabolicAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end

struct NormalAction{F<:Real} <: AbstractAction
    Th::F  # Threshold
    Sc::F  # Scaling factor
end


## Apple and Grapevine (BRIN) models 

include("species/struct.jl")


## Chilling model functions using parameters inside AbstractAction structs

function Rc(T, model::BinaryAction)
    return T < model.Th ? one(T) : zero(T)
end

function Rc(T, model::LinearAction)
    return T < model.Th ? (model.Th - T) / model.Sc : zero(T)
end

function Rc(T, model::ExponentialAction)
    return exp(-T / model.Th)
end

function Rc(T, model::SigmoidalAction)
    return 1 / (1 + exp((T - model.Th) / model.Sc))
end

function Rc(T, model::TriangularAction)
    r = 1 - abs(T - model.Th) / model.Sc
    return r < 0 ? zero(r) : r
end

function Rc(T, model::ParabolicAction)
    r = 1 - ((T - model.Th) / model.Sc)^2
    return r < 0 ? zero(r) : r
end

function Rc(T, model::NormalAction)
    return exp(-1 / 4 * (T - model.Th)^2 / model.Sc)
end

# For whole phenology model : 

Rc(T, model::AppleModel) = Rc(T, model.chilling_model)

Rc(T, model::BRIN_Model) = model.Q10^(-(T[1] / 10)) + model.Q10^(-(T[2] / 10)) #T = (TN_t,TX_t)
Rc(T, Q10::AbstractFloat) = Q10^(-(T[1] / 10)) + Q10^(-(T[2] / 10)) #T = (TN_t,TX_t)


## Forcing model functions using parameters inside AbstractAction structs

function Rf(T, model::BinaryAction)
    return T > model.Th ? one(T) : zero(T)
end

function Rf(T, model::LinearAction)
    return T > model.Th ? (T - model.Th) / model.Sc : zero(T)
end

function Rf(T, model::ExponentialAction)
    return exp(T / model.Th - 1)
end

function Rf(T, model::SigmoidalAction)
    return 1 / (1 + exp((model.Th - T) / model.Sc))
end

function Rf(T, model::TriangularAction)
    r = 1 - abs(T - model.Th) / model.Sc
    return r < 0 ? zero(r) : r
end

function Rf(T, model::ParabolicAction)
    r = 1 - ((T - model.Th) / model.Sc)^2
    return r < 0 ? zero(r) : r
end

function Rf(T, model::NormalAction)
    return exp(-1 / 4 * (T - model.Th)^2 / model.Sc)
end

# For whole phenology model :

Rf(T, model::AppleModel) = Rf(T, model.forcing_model)

# """
# Transforms T*(h,n) (called Th_raw here) into T(h,n) 
# """
Tcorrector(Th_raw, TOBc, TMBc) = (Th_raw - TOBc) * (TOBc <= Th_raw <= TMBc) + (TMBc - TOBc) * (TMBc < Th_raw)

function Rf(T, model::BRIN_Model)
    locTcorrector(Th_raw) = Tcorrector(Th_raw, model.T0Bc, model.TMBc)
    return sum(locTcorrector.([T[1] .+ (1:12) .* ((T[2] - T[1]) / 12); T[2] .- (1:12) .* ((T[2] - T[3]) / 12)])) #T = (TN_t,TX_t,TN_{t+1})
end
function Rf(T, (T0Bc, TMBc))
    locTcorrector(Th_raw) = Tcorrector(Th_raw, T0Bc, TMBc)
    return sum(locTcorrector.([T[1] .+ (1:12) .* ((T[2] - T[1]) / 12); T[2] .- (1:12) .* ((T[2] - T[3]) / 12)])) #T = (TN_t,TX_t,TN_{t+1})
end


function PhenoLoopStep(T, date_, model, EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing)
    if (month(date_), day(date_)) == model.CPO #If it's the start of the chilling 
        chilling = true
        sumchilling = 0.
    end
    if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
        sumchilling += Rc(T, model)
        if sumchilling > model.chilling_target #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
            push!(EB_vec, date_)
            chilling = false
            forcing = true
            sumforcing = 0.
        end
    end
    if forcing #For forcing, it's the same logic, and in the end we get the budburst date.
        sumforcing += Rf(T, model)
        if sumforcing > model.forcing_target
            push!(BB_vec, date_)
            forcing = false
        end
    end
    return EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing
end
function PhenoLoopStep(T, n::Integer, model, chilling, forcing, sumchilling, sumforcing)
    n += 1
    if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
        sumchilling += Rc(T, model)
        if sumchilling > model.chilling_target #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
            chilling = false
            forcing = true
            sumforcing = 0.
        end
    end
    if forcing #For forcing, it's the same logic, and in the end we get the budburst date.
        sumforcing += Rf(T, model)
        if sumforcing > model.forcing_target
            forcing = false
        end
    end
    return n, chilling, forcing, sumchilling, sumforcing
end
# Below model = [Rc_param,chilling_target,Rf_param,forcing_target]
function PhenoLoopStep(T, n::Integer, model::AbstractVector, chilling, forcing, sumchilling, sumforcing)
    n += 1
    if chilling #During chilling, each day we sum the chilling action function applied to the daily temperature.
        sumchilling += Rc(T, model[1])
        if sumchilling > model[2] #When the sum is superior to the chilling target, we swtich to the second part which is forcing.
            chilling = false
            forcing = true
            sumforcing = 0.
        end
    end
    if forcing #For forcing, it's the same logic, and in the end we get the budburst date.
        sumforcing += Rf(T, model[3])
        if sumforcing > model[4]
            forcing = false
        end
    end
    return n, chilling, forcing, sumchilling, sumforcing
end

function Pred_n(model, T::AbstractVector)
    chilling = true
    forcing = false
    sumchilling, sumforcing, n = 0, 0, 0
    while (chilling || forcing) && n < 365
        n, chilling, forcing, sumchilling, sumforcing = PhenoLoopStep(T[n+1], n, model, chilling, forcing, sumchilling, sumforcing)
    end
    return n
end
function Pred_n(model, x::AbstractMatrix)
    chilling = true
    forcing = false
    sumchilling, sumforcing, n = 0, 0, 0
    while (chilling || forcing) && n < 365
        n, chilling, forcing, sumchilling, sumforcing = PhenoLoopStep([x[n+1, :]; x[n+2, 1]], n, model, chilling, forcing, sumchilling, sumforcing)
    end
    return n
end
function Pred_n(model, TN::AbstractVector, TX::AbstractVector)
    chilling = true
    forcing = false
    sumchilling, sumforcing, n = 0, 0, 0
    while (chilling || forcing) && n < 365
        n, chilling, forcing, sumchilling, sumforcing = PhenoLoopStep((TN[n+1], TX[n+1], TN[n+2]), n, model, chilling, forcing, sumchilling, sumforcing)
    end
    return n
end