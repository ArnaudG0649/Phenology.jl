using Phenology, JLD2 #, CSV, DataFrames, DataFramesMeta, Dates
using Test

StationsPath = joinpath(@__DIR__, "..", "stations")

# cd("C:/Users/goninarn/.julia/dev/Phenology")

ref_data = load(joinpath(@__DIR__, "references.jld2"))["ref_data"]

@testset "Phenology.jl" begin
    # Write your tests here.

    ## Loading data

    df4 = extract_series(joinpath(StationsPath, "T_Nantes4.txt"))
    df8 = extract_series(joinpath(StationsPath, "T_Nantes8.txt"))

    df_TN_Montpellier = extract_series(joinpath(StationsPath, "TN_Montpellier.txt"))
    df_TN_Bonn = extract_series(joinpath(StationsPath, "TN_Bonn.txt"))
    df_TN_Nantes = extract_series(joinpath(StationsPath, "TN_Nantes.txt"))

    ## Apple  results :

    A_EB_Montpellier, A_BB_Montpellier = Apple_Phenology_Pred(joinpath(StationsPath, "TG_Montpellier.txt"))
    A_EB_Bonn, A_BB_Bonn = Apple_Phenology_Pred(joinpath(StationsPath, "TG_Bonn.txt"))
    A_EB_Nantes, A_BB_Nantes = Apple_Phenology_Pred(joinpath(StationsPath, "TG_Nantes.txt"))

    A_EB_Nantes4, A_BB_Nantes4 = Apple_Phenology_Pred(df4.TG, df4.DATE)
    A_EB_Nantes8, A_BB_Nantes8 = Apple_Phenology_Pred(df8.TG, df8.DATE)

    FRM_Montpellier = FreezingRiskMatrix(df_TN_Montpellier, A_BB_Montpellier)
    FRM_Bonn = FreezingRiskMatrix(df_TN_Bonn, A_BB_Bonn)
    FRM_Nantes = FreezingRiskMatrix(df_TN_Nantes, A_BB_Nantes)

    ## Grapevine results :

    G_EB_Montpellier, G_BB_Montpellier = Vine_Phenology_Pred(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
    G_EB_Bonn, G_BB_Bonn = Vine_Phenology_Pred(joinpath(StationsPath, "TN_Bonn.txt"), joinpath(StationsPath, "TX_Bonn.txt"))
    G_EB_Nantes, G_BB_Nantes = Vine_Phenology_Pred(joinpath(StationsPath, "TN_Nantes.txt"), joinpath(StationsPath, "TX_Nantes.txt"))

    G_EB_Nantes4, G_BB_Nantes4 = Vine_Phenology_Pred(df4)
    G_EB_Nantes8, G_BB_Nantes8 = Vine_Phenology_Pred(df8)

    @test A_EB_Montpellier == ref_data[1]
    @test A_EB_Bonn == ref_data[2]
    @test A_EB_Nantes == ref_data[3]
    @test A_EB_Nantes4 == ref_data[4]
    @test A_EB_Nantes8 == ref_data[5]
    @test A_BB_Montpellier == ref_data[6]
    @test A_BB_Bonn == ref_data[7]
    @test A_BB_Nantes == ref_data[8]
    @test A_BB_Nantes4 == ref_data[9]
    @test A_BB_Nantes8 == ref_data[10]
    @test G_EB_Montpellier == ref_data[11]
    @test G_EB_Bonn == ref_data[12]
    @test G_EB_Nantes == ref_data[13]
    @test G_EB_Nantes4 == ref_data[14]
    @test G_EB_Nantes8 == ref_data[15]
    @test G_BB_Montpellier == ref_data[16]
    @test G_BB_Bonn == ref_data[17]
    @test G_BB_Nantes == ref_data[18]
    @test G_BB_Nantes4 == ref_data[19]
    @test G_BB_Nantes8 == ref_data[20]
    @test FRM_Montpellier == ref_data[21]
    @test FRM_Bonn == ref_data[22]
    @test FRM_Nantes == ref_data[23]
    #If ref_results is executed, replace "DB" with "EB" in the name of the ref variables (for exemple A_DB_Montpellier_ref -> A_EB_Montpellier_ref)

    df_vassal_chasselas = @chain begin
        DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "Data_BB.xlsx"), "data_Tempo"))
        @subset(:variete_cultivar_ou_provenance .== "Chasselas")
        @subset(:nom_du_site .== "INRA Domaine de Vassal")
    end

    #Testing apple model with Pred_n

    df_TG_Montpellier = extract_series(joinpath(StationsPath, "TG_Montpellier.txt"))
    TG_vec, date_vec = Take_temp_year(df_TG_Montpellier, 2020, CPO=(10, 30)), df_TG_Montpellier.DATE[Iyear_CPO(df_TG_Montpellier.DATE, 2020, CPO=(10, 30))]
    @test length(Date(2019, 10, 30):Apple_Phenology_Pred(TG_vec, date_vec)[2][1]) == Pred_n(AppleModel(), TG_vec)


    #Testing grapevine model with Pred_n

    date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
    x_2020, date_vec_2020 = Take_temp_year(x, date_vec, 2020), date_vec[Iyear_CPO(date_vec, 2020, CPO=(8, 1))]
    @test length(Date(2019, 8, 1):Vine_Phenology_Pred(x_2020, date_vec_2020)[2][1]) == Pred_n(BRIN_Model(), x_2020)

end
