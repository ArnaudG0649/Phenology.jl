using Phenology, JLD2 #, CSV, DataFrames, DataFramesMeta, Dates
using Test

StationsPath ="stations"

# cd("C:/Users/goninarn/.julia/dev/Phenology")

@load "test/references.jld2"

@testset "Phenology.jl" begin
    # Write your tests here.

    ## Loading data

    df4 = extract_series(joinpath(StationsPath,"T_Nantes4.txt"))
    df8 = extract_series(joinpath(StationsPath,"T_Nantes8.txt"))

    df_TN_Montpellier = extract_series(joinpath(StationsPath,"TN_Montpellier.txt"))
    df_TN_Bonn = extract_series(joinpath(StationsPath,"TN_Bonn.txt"))
    df_TN_Nantes = extract_series(joinpath(StationsPath,"TN_Nantes.txt"))

    ## Apple  results :

    A_EB_Montpellier, A_BB_Montpellier = Apple_Phenology_Pred(joinpath(StationsPath,"TG_Montpellier.txt"))
    A_EB_Bonn, A_BB_Bonn = Apple_Phenology_Pred(joinpath(StationsPath,"TG_Bonn.txt"))
    A_EB_Nantes, A_BB_Nantes = Apple_Phenology_Pred(joinpath(StationsPath,"TG_Nantes.txt"))

    A_EB_Nantes4, A_BB_Nantes4 = Apple_Phenology_Pred(df4.TG,df4.DATE)
    A_EB_Nantes8, A_BB_Nantes8 = Apple_Phenology_Pred(df8.TG,df8.DATE)

    FRM_Montpellier = FreezingRiskMatrix(df_TN_Montpellier, A_BB_Montpellier)
    FRM_Bonn = FreezingRiskMatrix(df_TN_Bonn, A_BB_Bonn)
    FRM_Nantes = FreezingRiskMatrix(df_TN_Nantes, A_BB_Nantes)

    ## Grapevine results :

    G_EB_Montpellier, G_BB_Montpellier = Vine_Phenology_Pred(joinpath(StationsPath,"TN_Montpellier.txt"), joinpath(StationsPath,"TX_Montpellier.txt"))
    G_EB_Bonn, G_BB_Bonn = Vine_Phenology_Pred(joinpath(StationsPath,"TN_Bonn.txt"), joinpath(StationsPath,"TX_Bonn.txt"))
    G_EB_Nantes, G_BB_Nantes = Vine_Phenology_Pred(joinpath(StationsPath,"TN_Nantes.txt"), joinpath(StationsPath,"TX_Nantes.txt"))

    G_EB_Nantes4, G_BB_Nantes4 = Vine_Phenology_Pred(df4)
    G_EB_Nantes8, G_BB_Nantes8 = Vine_Phenology_Pred(df8)

    @test A_EB_Montpellier == A_DB_Montpellier_ref
    @test A_EB_Bonn == A_DB_Bonn_ref    
    @test A_EB_Nantes == A_DB_Nantes_ref
    @test A_EB_Nantes4 == A_DB_Nantes4_ref
    @test A_EB_Nantes8 == A_DB_Nantes8_ref
    @test A_BB_Montpellier == A_BB_Montpellier_ref
    @test A_BB_Bonn == A_BB_Bonn_ref
    @test A_BB_Nantes == A_BB_Nantes_ref
    @test A_BB_Nantes4 == A_BB_Nantes4_ref
    @test A_BB_Nantes8 == A_BB_Nantes8_ref
    @test FRM_Montpellier == FRM_Montpellier_ref
    @test FRM_Bonn == FRM_Bonn_ref
    @test FRM_Nantes == FRM_Nantes_ref
    @test G_EB_Montpellier == G_DB_Montpellier_ref
    @test G_EB_Bonn == G_DB_Bonn_ref    
    @test G_EB_Nantes == G_DB_Nantes_ref
    @test G_EB_Nantes4 == G_DB_Nantes4_ref
    @test G_EB_Nantes8 == G_DB_Nantes8_ref
    @test G_BB_Montpellier == G_BB_Montpellier_ref
    @test G_BB_Bonn == G_BB_Bonn_ref
    @test G_BB_Nantes == G_BB_Nantes_ref
    @test G_BB_Nantes4 == G_BB_Nantes4_ref
    @test G_BB_Nantes8 == G_BB_Nantes8_ref
    #If ref_results is executed, replace "DB" with "EB" in the name of the ref variables (for exemple A_DB_Montpellier_ref -> A_EB_Montpellier_ref)
end
