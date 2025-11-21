using Phenology, JLD2, CSV, DataFrames, DataFramesMeta, Dates, XLSX, Optimization, OptimizationOptimJL, OptimizationBBO, ForwardDiff
StationsPath = joinpath(@__DIR__, "..", "stations")

df = DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
df_n = @by(df, [:variete_cultivar_ou_provenance], :n = length(:variete_cultivar_ou_provenance))


df_vassal_chasselas = @chain begin
    DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
    @subset(:variete_cultivar_ou_provenance .== "Chasselas")
    @subset(:nom_du_site .== "INRA Domaine de Vassal")
end

df_vassal_chasselas == read_pheno_table("Chasselas", "INRA Domaine de Vassal", file=joinpath(@__DIR__, "..", "Data_BB.xlsx"))
