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


# # Abstract type for Temperature Codes
# abstract type AbstractWeatherTemperature end
# abstract type AbstracTemperature <: AbstractWeatherTemperature end


# # Concrete types for temperature codes
# mutable struct TN <: AbstracTemperature
#     df::DataFrame
#     TN(df) = new(df[:, [:DATE, :TN]])
# end
# mutable struct TG <: AbstracTemperature
#     df::DataFrame
#     TG(df) = new(df[:, [:DATE, :TG]])
# end
# mutable struct TX <: AbstracTemperature
#     df::DataFrame
#     TX(df) = new(df[:, [:DATE, :TX]])
# end

# TN(x::AbstractVector{<:AbstractFloat}, date_vec::AbstractVector{Date}) = TN(DataFrame(Dict(:DATE => date_vec, :TN => x)))
# TN(file::String) = TN(extract_series(file))

# TG(x::AbstractVector{<:AbstractFloat}, date_vec::AbstractVector{Date}) = TG(DataFrame(Dict(:DATE => date_vec, :TG => x)))
# TG(file::String) = TG(extract_series(file))

# TX(x::AbstractVector{<:AbstractFloat}, date_vec::AbstractVector{Date}) = TX(DataFrame(Dict(:DATE => date_vec, :TX => x)))
# TX(file::String) = TX(extract_series(file))


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


# @concrete struct AppleModel
#     CPO::Tuple{<:Integer,<:Integer}
#     chilling_model::AbstractAction
#     chilling_target::AbstractFloat
#     forcing_model::AbstractAction
#     forcing_target::AbstractFloat
#     AppleModel(CPO=(10, 30), chilling_model=TriangularAction(1.1, 20.), chilling_target=56.0, forcing_model=ExponentialAction(9.0), forcing_target=83.58) = new(CPO, chilling_model, chilling_target, forcing_model, forcing_target)
# end

# @concrete struct BRIN_Model
#     CPO::Tuple{<:Integer,<:Integer}
#     Q10::AbstractFloat
#     chilling_target::AbstractFloat #Cc
#     T0Bc::AbstractFloat
#     TMBc::AbstractFloat
#     forcing_target::AbstractFloat #Ghc
#     BRIN_Model(CPO=(8, 1), Q10=2.17, chilling_target=119.0, T0Bc=8.19, TMBc=25., forcing_target=13236) = new(CPO, Q10, chilling_target, T0Bc, TMBc, forcing_target)
# end