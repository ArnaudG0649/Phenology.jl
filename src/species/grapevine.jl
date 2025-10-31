"""
    Vine_Phenology_Pred(TN_vec::AbstractVector, TX_vec::AbstractVector, date_vec::AbstractVector{Date}; model::BRIN_Model=BRIN_Model())
    Vine_Phenology_Pred(file_TN::String, file_TX::String; model::BRIN_Model=BRIN_Model())
    Vine_Phenology_Pred(df_TN::DataFrame, df_TX::DataFrame; model::BRIN_Model=BRIN_Model())
    Vine_Phenology_Pred(df::DataFrame; model::BRIN_Model=BRIN_Model())

From a series of TN `TN_vec`, a series of TX `TX_vec`, their dates in `date_vec` and a vine phenology model `model`, return the endodormancy break dates and budburst dates in two vectors respectively.
The temperatures and dates data can be included in two .txt file, two different dataframes or one dataframe with the two type of temperature. See [Temperatures data compatibility](@ref) for further explanation about the way to input temperatures data.
"""
function Vine_Phenology_Pred(Tn_vec::AbstractVector,
    Tx_vec::AbstractVector,
    date_vec::AbstractVector{Date};
    model::BRIN_Model=BRIN_Model())
    EB_vec = Date[]
    BB_vec = Date[]
    chilling, forcing = false, false
    sumchilling, sumforcing = 0., 0.
    for (Tn, Tx, date_, Tn1) in zip(Tn_vec[1:(end-1)], Tx_vec[1:(end-1)], date_vec[1:(end-1)], Tn_vec[2:end]) #Tn1 = TN(n+1)
        EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing = PhenoLoopStep((Tn, Tx, Tn1), date_, model, EB_vec, BB_vec, chilling, forcing, sumchilling, sumforcing)
    end
    forcing == true ? pop!(EB_vec) : nothing #forcing == true at the end means that it added a EB date in EB_vec which won't have it corresponding BB date in BB_vec
    return EB_vec, BB_vec
end


function Vine_Phenology_Pred(df_TN::DataFrame, df_TX::DataFrame;
    model::BRIN_Model=BRIN_Model())
    date_vec, x = Common_indexes([df_TN, df_TX])
    return Vine_Phenology_Pred(x[:, 1], x[:, 2], date_vec, model=model)
end

function Vine_Phenology_Pred(
    file_TN::String,
    file_TX::String;
    model::BRIN_Model=BRIN_Model())

    date_vec, x = Common_indexes(file_TN, file_TX)
    return Vine_Phenology_Pred(x[:, 1], x[:, 2], date_vec, model=model)
end

function Vine_Phenology_Pred(df::DataFrame;
    model::BRIN_Model=BRIN_Model())
    return Vine_Phenology_Pred(df.TN, df.TX, df.DATE, model=model)
end