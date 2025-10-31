using Phenology, JLD2, CSV, DataFrames, DataFramesMeta, Dates

# include("table_reader_dep.jl")

StationsPath = "stations"

TN_temp_Montpellier = initTN(joinpath(StationsPath, "TN_Montpellier.txt"))
TN_temp_Bonn = initTN(joinpath(StationsPath, "TN_Bonn.txt"))
TN_temp_Nantes = initTN(joinpath(StationsPath, "TN_Nantes.txt"))

df4 = extract_series_DRIAS(joinpath(StationsPath, "T_Nantes4.txt"))
df8 = extract_series_DRIAS(joinpath(StationsPath, "T_Nantes8.txt"))

## Making apple reference results :

A_EB_Montpellier_ref, A_BB_Montpellier_ref = Apple_Phenology_Pred(initTG(joinpath(StationsPath, "TG_Montpellier.txt")))
A_EB_Bonn_ref, A_BB_Bonn_ref = Apple_Phenology_Pred(initTG(joinpath(StationsPath, "TG_Bonn.txt")))
A_EB_Nantes_ref, A_BB_Nantes_ref = Apple_Phenology_Pred(initTG(joinpath(StationsPath, "TG_Nantes.txt")))

A_EB_Nantes4_ref, A_BB_Nantes4_ref = Apple_Phenology_Pred(initTG(df4))
A_EB_Nantes8_ref, A_BB_Nantes8_ref = Apple_Phenology_Pred(initTG(df8))

FRM_Montpellier_ref = FreezingRiskMatrix(TN_temp_Montpellier, A_BB_Montpellier_ref)
FRM_Bonn_ref = FreezingRiskMatrix(TN_temp_Bonn, A_BB_Bonn_ref)
FRM_Nantes_ref = FreezingRiskMatrix(TN_temp_Nantes, A_BB_Nantes_ref)

## Making grapevine reference results :

G_EB_Montpellier_ref, G_BB_Montpellier_ref = Vine_Phenology_Pred(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
G_EB_Bonn_ref, G_BB_Bonn_ref = Vine_Phenology_Pred(joinpath(StationsPath, "TN_Bonn.txt"), joinpath(StationsPath, "TX_Bonn.txt"))
G_EB_Nantes_ref, G_BB_Nantes_ref = Vine_Phenology_Pred(joinpath(StationsPath, "TN_Nantes.txt"), joinpath(StationsPath, "TX_Nantes.txt"))

G_EB_Nantes4_ref, G_BB_Nantes4_ref = Vine_Phenology_Pred(df4.TN, df4.TX, df4.DATE)
G_EB_Nantes8_ref, G_BB_Nantes8_ref = Vine_Phenology_Pred(df8.TN, df8.TX, df8.DATE)


@save("test/references.jld2", 
A_EB_Montpellier_ref, 
A_EB_Bonn_ref,
A_EB_Nantes_ref,
A_EB_Nantes4_ref,
A_EB_Nantes8_ref,
A_BB_Montpellier_ref,
A_BB_Bonn_ref,
A_BB_Nantes_ref,
A_BB_Nantes4_ref,
A_BB_Nantes8_ref,
G_EB_Montpellier_ref,
G_EB_Bonn_ref,
G_EB_Nantes_ref,
G_EB_Nantes4_ref,
G_EB_Nantes8_ref,
G_BB_Montpellier_ref,
G_BB_Bonn_ref,
G_BB_Nantes_ref,
G_BB_Nantes4_ref,
G_BB_Nantes8_ref,
FRM_Montpellier_ref,
FRM_Bonn_ref,
FRM_Nantes_ref
)