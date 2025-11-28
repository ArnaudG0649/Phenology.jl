using Phenology, JLD2, CSV, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, OptimizationBBO, ForwardDiff
StationsPath = joinpath(@__DIR__, "..", "stations")

df = DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
df_n = @by(df, [:variete_cultivar_ou_provenance], :n = length(:variete_cultivar_ou_provenance))


df_vassal_chasselas = @chain begin
    DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
    @subset(:variete_cultivar_ou_provenance .== "Chasselas")
    @subset(:nom_du_site .== "INRA Domaine de Vassal")
end

BB_vec = Date.(read_pheno_table("Chasselas", "INRA Domaine de Vassal", file=joinpath(@__DIR__, "..", "Data_BB.xlsx")).date)

date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))

model = BRIN_Model(date_vec, x, BB_vec)


# XLSX.writetable("Data_BB_Hainfeld.xlsx", df_koch_final)

