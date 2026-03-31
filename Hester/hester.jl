using OrderedCollections

ind(date_vec, date1, date2) = findfirst(date_vec .== date1):findfirst(date_vec .== date2)
ind(date_vec, date) = findfirst(date_vec .== date):length(date_vec)

w_step(w, P, R, CHO, ρ; Ψ=0.667) = w + (Ψ * (P - R) + CHO) * ρ
# w_step_common(P, R, CHO; Ψ=0.667) = Ψ * (P - R) + CHO
# w_step(w, common, ρ) = w + common * ρ

Photosynthesis(S, h, LAI; α=14600, Pmax=0.00075, K=0.6) = (α * S * h * Pmax * (1 - exp(-K * LAI))) / (α * S * K + h * Pmax)

#Respiration
Respiration(TG, α, β) = α * exp(β * TG)
RespirationL(TG, αL=0.5182, βL=0.084) = Respiration(TG, αL, βL)
RespirationW(TG, αW=0.000719, βW=0.084) = Respiration(TG, αW, βW)
RespirationR(TG, αR=0.001545, βR=0.084) = Respiration(TG, αR, βR)
RespirationF(TG, αF=0.00411, βF=0.084) = Respiration(TG, αF, βF)

w_to_LA(w) = w * (75E-4) + 95E-6
w_to_LA(w, TCSA; χ=0.794) = min(w_to_LA(w), χ * TCSA)

# Solar_radiation_approx(t::Integer) = Sm + Sm*(0.0186Lat-0.12) * sin(2*π*(t+283)/365) 
# Solar_radiation_approx(t::Integer) = Sm*((0.0186Lat-0.12) * sin(2*π*(t+283)/365) + 1)
Solar_radiation_approx(Lat, t::Integer) = (24.3 - 0.264Lat) * ((0.0186Lat - 0.12) * sin(2 * π * (t + 283) / 365) + 1)
Solar_radiation_approx(Lat, t::Date) = Solar_radiation_approx(Lat, dayofyear(t))

#CHO
Reserve_use(wr1, ww1; ξ=0.05) = ξ * (wr1 + ww1)
#EB : Endodormancy break, FB : Full bloom (both Date type)

#Trunk Cross-Sectional Area
TCSA_f(Age, TCSA_0=1.57, μ=1.32, δ=0.3) = TCSA_0 * exp(μ * (1 - exp(-δ * Age)) / δ)

#Proportions 
Proportion(FL, θ, λ, τ) = θ + λ * FL / (τ + FL)
ProportionL(FL; θL=0.18, λL=-0.085, τL=6.85) = Proportion(FL, θL, λL, τL)
ProportionW(FL; θW=0.41, λW=-0.3, τW=6.05) = Proportion(FL, θW, λW, τW)
ProportionF(FL; θF=0, λF=0.86, τF=9.6) = Proportion(FL, θF, λF, τF)


"""
    Hester_model(TG_vec, date_vec, EB, BB, FB, wtot ; Lat, CPO, Age=10, GA=10, NF=150)

Simulates the evolution of the biomass of the four components of an apple tree (Wood, root, leaf and fruit) over a year cycle and return the results in a `Dataframe` object.
Parameters : 
- `TG_vec` : vector of daily mean temperatures over the cycle (from the CPO to the next year's CPO)
- `date_vec` : vector of dates corresponding to the `TG_vec`
- `EB` : date of endodormancy break
- `BB` : date of budburst
- `FB` : date of full bloom
- `wtot` : total biomass of the tree
- `Solar_radiation` : vector of solar radiations. If it's equal to `nothing` (default) a sinosoïdal approximation is used instead.
- `Lat` : latitude of the location of the tree
- `CPO` : tuple of the month and day of the CPO
- `NF` : number of fruits (default: 150)
- `GA` : growth area (default: 10)
- `TCSA` : trunk cross-sectional area (default:TCSA_f(Age))
"""
function Hester_model(TG_vec,
    date_vec,
    EB::Date,
    BB::Date,
    FB::Date,
    wtot;
    Solar_radiation=nothing,
    Lat=43.3314,
    CPO=(9, 1),
    Age=10,
    GA=10,
    NF=150,
    TCSA=TCSA_f(Age),
    zero_CHO_wr=true)

    history_wl = Float64[]
    history_ww = Float64[]
    history_wf = Float64[]
    history_wr = Float64[]
    history_ρl = Float64[]
    history_ρw = Float64[]
    history_ρf = Float64[]
    history_ρr = Float64[]
    history_LA = Float64[]
    history_P = Float64[]

    ρl = 0.
    ρw = ProportionW(10^20)
    ρf = 0.
    ρr = 1 - ρw

    wl = 0.
    ww = wtot * ρw
    wf = 0.
    wr = wtot * ρr

    LA = 10^-20

    for (i, (TG, date)) in enumerate(zip(TG_vec, date_vec))

        if date == BB
            wr1, ww1 = wr, ww
        end
        Growing_Leaf = BB <= date <= max(Date(year(FB), CPO[1], CPO[2]) - Day(1), FB + Day(90)) #p.25
        Growing_Fruit = FB <= date <= max(Date(year(FB), CPO[1], CPO[2]) - Day(1), FB + Day(90))

        S = isnothing(Solar_radiation) ? Solar_radiation_approx(Lat, date) : Solar_radiation[i]
        h = 3600 * daylength_cbm(Lat, date)

        P = Photosynthesis(S, h, LA / GA)
        # R = Respiration(TG) #Pareil tout le temps ??!
        Rl = RespirationL(TG)
        Rw = RespirationW(TG)
        Rf = RespirationF(TG)
        Rr = RespirationR(TG)

        LA = w_to_LA(wl, TCSA)
        FL = NF / LA

        ρl = Growing_Leaf ? ProportionL(FL) : 0.
        ρw = ProportionW(FL)
        ρf = Growing_Fruit ? ProportionF(FL) : 0.
        ρr = 1 - ρl - ρw - ρf

        CHO = EB <= date < FB ? Reserve_use(history_wr[1], history_ww[1], ξ=0.05) : 0.

        CHO_wr = zero_CHO_wr ? 0 : CHO
        wl = w_step(wl, P, Rl, CHO, ρl)
        ww = w_step(ww, P, Rw, CHO_wr, ρw)
        wf = w_step(wf, P, Rf, CHO, ρf)
        wr = w_step(wr, P, Rr, CHO_wr, ρr)

        push!(history_wl, wl)
        push!(history_ww, ww)
        push!(history_wf, wf)
        push!(history_wr, wr)
        push!(history_ρl, ρl)
        push!(history_ρw, ρw)
        push!(history_ρf, ρf)
        push!(history_ρr, ρr)
        push!(history_LA, LA)
        push!(history_P, P)

    end

    results_df = DataFrame(
        date=date_vec,
        wl=history_wl,
        ww=history_ww,
        wf=history_wf,
        wr=history_wr,
        ρl=history_ρl,
        ρw=history_ρw,
        ρf=history_ρf,
        ρr=history_ρr,
        LA=history_LA,
        P=history_P,
    )
    return results_df
end


#To calculate TCSA_lim
TCSA_0 = 1.57
μ = 1.32
δ = 0.3

"""
    Hester_model(TG_vec, date_vec, EB_vec, FB_vec, wtot)

Simulates the evolution of the biomass of the four components of an apple tree (Wood, root, leaf and fruit) over the whole timeline in date_vec and return the results in a dictionnary of `Dataframe` objects where the keys are the year and the value the dateframe of results.
If `GA` is not precised or = 0, the growth area at for each year is equal to GA = GAr * TCSA.
If `GAr` is also not precised or = 0, the growth area is automatically chosen according to the value `cGA` and this equation : cGA = GAr * TCSA_lim where TCSA_lim is limit of TCSA when Age -> +∞.
If `NF` = 0, the number of fruit is determined by NF = NFr * TCSA with NFr = cNF/TCSA_lim. 
Parameters : 
- `TG_vec` : vector of daily mean temperatures
- `date_vec` : vector of dates corresponding to the `TG_vec`
- `EB_vec` : dates of endodormancy break
- `FB_vec` : dates of full bloom
- `wtot` : total biomass of the tree at the beginning
- `Solar_radiation` : vector of solar radiations. If it's equal to `nothing` (default) a sinosoïdal approximation is used instead.
- `Lat` : latitude of the location of the tree
- `CPO` : tuple of the month and day of the CPO
- `Age` : age of the tree (default: 10)
- `NF` : number of fruits (default: 150)
- `cNF` : number of fruits at convergence of TCSA (default: 400). Useless if NF>0.
- `cGA` : growth area at convergence of TCSA (default:10)
- `GA` : growth area for each year (default: 0)
- `GAr` : growth area rate (default:0)
- `n_pre_series` : number of years of temperatures created "artificially" before the first day with the function `Pre_series` for the burning period. (default:0).
"""
function Hester_model(TG_vec,
    date_vec,
    EB_vec::AbstractVector{Date},
    BB_vec::AbstractVector{Date},
    FB_vec::AbstractVector{Date},
    wtot;
    Solar_radiation=nothing,
    Lat=43.3314,
    CPO=(9, 1),
    Age=50,
    NF=200,
    cNF=0,
    cGA=0,
    GA=5,
    GAr=0,
    zero_CHO_wr=true,
    n_pre_series=20
)
    if n_pre_series > 0
        New_TG_vec, New_date_vec = Pre_series(TG_vec, date_vec, n_pre_series)
        TG_vec, date_vec = [New_TG_vec; TG_vec], [New_date_vec; date_vec]
        EB_vec, BB_vec, FB_vec = [reverse([EB_vec[1] - Year(i) for i in 1:n_pre_series]); EB_vec], [reverse([BB_vec[1] - Year(i) for i in 1:n_pre_series]); BB_vec], [reverse([FB_vec[1] - Year(i) for i in 1:n_pre_series]); FB_vec]
    end

    GA_vec = Float64[]
    GA == 0 ? GAr == 0 ? GAr = cGA / (TCSA_0 * exp(μ / δ)) : nothing : nothing
    NF == 0 ? NFr = cNF / (TCSA_0 * exp(μ / δ)) : nothing
    df_dict = OrderedDict{Integer}{DataFrame}()

    for (EB, BB, FB) in zip(EB_vec, BB_vec, FB_vec)
        Can_apply_Hester = true
        Index = 1:2
        println(year(FB))
        try
            Index = ind(date_vec, Date(year(FB) - 1, CPO[1], CPO[2]), max(Date(year(FB), CPO[1], CPO[2]) - Day(1), FB + Day(90)))
        catch
            println("Impossible to simulate the cycle $(year(FB)-1)-$(year(FB))")
            Can_apply_Hester = false
        end

        if Can_apply_Hester
            sub_TG_vec, sub_date_vec = TG_vec[Index], date_vec[Index]
            sub_solar_radiation = isnothing(Solar_radiation) ? nothing : Solar_radiation[Index]
            TCSA = TCSA_f(Age)
            Eff_GA = GA == 0 ? GAr * TCSA : GA
            Eff_NF = NF == 0 ? NFr * TCSA : NF
            df = Hester_model(sub_TG_vec, sub_date_vec, EB, BB, FB, wtot; Solar_radiation=sub_solar_radiation, Lat=Lat, CPO=CPO, GA=Eff_GA, NF=Eff_NF, TCSA=TCSA, zero_CHO_wr=zero_CHO_wr)
            df_dict[year(FB)] = df
            Age += 1
            wtot = df.ww[end] + df.wr[end]
            push!(GA_vec, Eff_GA)
        end
    end
    return df_dict, GA_vec
end

"""
    Pre_series(T_vec, date_vec, n)

Return an extension of the series of temperatures `T_vec` and dates `date_vec` of `n` years before the first date of `date_vec`.
The extension is done by repeating the first leap year of the series `n` times.
If there is no leap year in the series, the first year is repeated with an added day at the end of February.
The utility of this function is for making a burning period for the Hester model.
"""
function Pre_series(T_vec, date_vec, n)
    if any(isleapyear.(date_vec))
        day1_index = findfirst(month.(date_vec) .== 1 .&& day.(date_vec) .== 1 .&& isleapyear.(date_vec))
        Sub_T_vec = T_vec[day1_index:(day1_index+365)]
    else
        day1_index = findfirst(month.(date_vec) .== 1 .&& day.(date_vec) .== 1)
        Sub_T_vec = T_vec[day1_index:(day1_index+58)]
        push!(Sub_T_vec, (T_vec[day1_index+58] + T_vec[day1_index+59]) / 2)
        append!(Sub_T_vec, T_vec[(day1_index+59):(day1_index+364)])
    end
    New_date_vec = (date_vec[1]-Year(n)):(date_vec[1]-Day(1))
    New_t_vec = Sub_T_vec[dayofyear_Leap.(New_date_vec)]
    return New_t_vec, New_date_vec
end