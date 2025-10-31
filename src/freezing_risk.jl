"""
    FreezingRisk(TN_vec::AbstractVector, Date_vec::AbstractVector{Date}, BB::Date; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    FreezingRisk(df::DataFrame, BB; threshold=-2., PeriodOfInterest=Month(3), CPO=(8, 1))

For a given budburst date `BB` return the number of days with minimal temperature inferior to `threshold` for the period `PeriodOfInterest` after this date but always before the next chilling period onset `CPO` (next phenological cycle).
"""
function FreezingRisk(TN_vec::AbstractVector, Date_vec::AbstractVector{Date}, BB::Date; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    if BB ∉ Date_vec || min(BB + PeriodOfInterest, Date(year(BB), CPO[1], CPO[2])) ∉ Date_vec
        return -1
    end
    I = findall(BB .<= Date_vec .<= min(BB + PeriodOfInterest, Date(year(BB), CPO[1], CPO[2])))
    return sum(TN_vec[I] .<= threshold)
end

function FreezingRisk(df::DataFrame, BB; threshold=-2., PeriodOfInterest=Month(3), CPO=(8, 1))
    return FreezingRisk(df.TN, df.DATE, BB, threshold=threshold, PeriodOfInterest=PeriodOfInterest, CPO=CPO)
end

"""
    FreezingRiskMatrix(TN_vec, Date_vec, date_vecBB::AbstractVector{Date}; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))

For a given budburst date vector `date_vecBB` return the number of days with minimal temperature inferior to `threshold` for each year in a N x 2 matrix
"""
function FreezingRiskMatrix(TN_vec, Date_vec, date_vecBB::AbstractVector{Date}; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    FreezingRiskBB(BB) = FreezingRisk(TN_vec, Date_vec, BB, threshold=threshold, PeriodOfInterest=PeriodOfInterest, CPO=CPO)
    return [year.(date_vecBB) FreezingRiskBB.(date_vecBB)]
end

function FreezingRiskMatrix(df::DataFrame, date_vecBB::AbstractVector{Date}; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    FreezingRiskBB(BB) = FreezingRisk(df, BB, threshold=threshold, PeriodOfInterest=PeriodOfInterest, CPO=CPO)
    return [year.(date_vecBB) FreezingRiskBB.(date_vecBB)]
end

"""
    FreezingRiskMatrix(TN_vecs, Date_vec, date_vecsBB; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))

For a sample of daily minimal temperatures series `TN_vecs` and their respectives budburst dates `date_vecsBB` return a matrix with the number of scenarios which have n days with minimal temperature inferior to `threshold` for n in row and the year in column.
"""
function FreezingRiskMatrix(TN_vecs, Date_vec, date_vecsBB; threshold=-2., PeriodOfInterest=Month(3), CPO=(10, 30))
    Mat_vec = [FreezingRiskMatrix(Tn_vec, Date_vec, date_vecBB, threshold=threshold, PeriodOfInterest=PeriodOfInterest, CPO=CPO) for (Tn_vec, date_vecBB) in zip(TN_vecs, date_vecsBB)]
    Conc_Mat_vec = vcat(Mat_vec...)
    Conc_Mat_vec2 = [(Conc_Mat_vec[:, 1] .- minimum(Conc_Mat_vec[:, 1]) .+ 1) (Conc_Mat_vec[:, 2] .- minimum(Conc_Mat_vec[:, 2]) .+ 1)]
    I, J = maximum(Conc_Mat_vec2[:, 2]), maximum(Conc_Mat_vec2[:, 1])
    Result_Mat = zeros(I, J)
    for i in 1:I
        for j in 1:J
            Result_Mat[i, j] = sum(Conc_Mat_vec2[:, 1] .== j .&& Conc_Mat_vec2[:, 2] .== i)
        end
    end
    return Result_Mat, sort(unique(Conc_Mat_vec[:, 1])), sort(unique(Conc_Mat_vec[:, 2]))
end