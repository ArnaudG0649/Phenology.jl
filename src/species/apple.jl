"""
    Apple_Phenology_Pred(TG_vec::AbstractVector, date_vec::AbstractVector{Date}; model::AppleModel=AppleModel())
    Apple_Phenology_Pred(df::DataFrame; model::AppleModel=AppleModel())
    Apple_Phenology_Pred(file_TG::String; model::AppleModel=AppleModel())

From a series of daily average temperature `TG_vec`, its dates in `date_vec` and an apple phenology model `model`, return the endodormancy break dates and budburst dates in two vectors respectively.
The temperatures and dates data can be included in a dataframe (second method) or in a .txt file (third method). See [Temperatures data compatibility](@ref) for further explanation about the way to input temperatures data.
"""
function Apple_Phenology_Pred(TG_vec::AbstractVector,
    date_vec::AbstractVector{Date};
    model::AppleModel=AppleModel())
    EB_vec = Date[]
    BB_vec = Date[]
    chilling, forcing = false, false
    sumchilling, sumforcing = 0., 0.
    for (Tg, date_) in zip(TG_vec, date_vec)
        EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing = PhenoLoopStep(Tg, date_, model, EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing)
    end
    forcing ? pop!(EB_vec) : nothing #forcing == true at the end means that it added a EB date in EB_vec which won't have it corresponding BB date in BB_vec
    return EB_vec, BB_vec
end

function Apple_Phenology_Pred(df::DataFrame;
    model::AppleModel=AppleModel())
    return Apple_Phenology_Pred(df.TG,
        df.DATE,
        model=model)
end

function Apple_Phenology_Pred(file_TG::String;
    model::AppleModel=AppleModel())
    df = extract_series(file_TG)
    return Apple_Phenology_Pred(df.TG,df.DATE,
        model=model)
end