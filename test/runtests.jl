using Phenology, JLD2 ,DataFrames, DataFramesMeta, Dates, XLSX
using Test

# GetAllAttributes(object) = map(field -> getfield(object, field), fieldnames(typeof(object)))
# ## Source : https://discourse.julialang.org/t/get-the-name-and-the-value-of-every-field-for-an-object/87052/2

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
    years = df_vassal_chasselas.annee

    #Testing apple model with Pred_n

    df_TG_Montpellier = extract_series(joinpath(StationsPath, "TG_Montpellier.txt"))
    TG_vecs, date_vecs = map(y -> Take_temp_year(df_TG_Montpellier, y, CPO=(10, 30)), years), map(y -> df_TG_Montpellier.DATE[Iyear_CPO(df_TG_Montpellier.DATE, y, CPO=(10, 30))], years)
    @test [length(Date(year - 1, 10, 30):Apple_Phenology_Pred(TG_vec, date_vec)[2][1]) for (year, TG_vec, date_vec) in zip(years, TG_vecs, date_vecs)] == map(TG_vec -> Pred_n(AppleModel(), TG_vec), TG_vecs)


    #Testing grapevine model with Pred_n

    date_vec, x = Common_indexes(joinpath(StationsPath, "TN_Montpellier.txt"), joinpath(StationsPath, "TX_Montpellier.txt"))
    x_vec, date_vecs = map(y -> Take_temp_year(x, date_vec, y), years), map(y -> date_vec[Iyear_CPO(date_vec, y, CPO=(8, 1))], years)
    @test [length(Date(year - 1, 8, 1):Vine_Phenology_Pred(x, date_vec)[2][1]) for (year, x, date_vec) in zip(years, x_vec, date_vecs)] == map(x -> Pred_n(BRIN_Model(), x), x_vec)

    #Testing training on toy data

    #Taking the avaible years
    years = unique(year.(date_vec))
    complete_year_index = findall(year -> Date(year - 1, 8, 1):Date(year, 8, 1) ⊆ date_vec, years)
    years = years[complete_year_index]

    #Separating the temperature for each year conveniently to be used by Pred_n function
    x_vec = [Take_temp_year(x, date_vec, year) for year in years]

    #Defining training data
    model_target = BRIN_Model((8, 1), 2.17, 111., 5, 25, 6578.3)
    n_train = [Pred_n(model_target, x) for x in x_vec]

    #Training data and comparing results with true data
    model = BRIN_Model(date_vec, x, years, n_train .- length(Date(0, 8, 1):Date(0, 12, 31)))
    n_pred = [Pred_n(model, x) for x in x_vec]
    Δ = n_train .- n_pred
    @test sum(Δ .== 0) / length(Δ) > 0.975

end
