module PhenoTest

export initTN, initTG, initTX, Apple_Phenology_Pred, Vine_Phenology_Pred, FreezingRisk, FreezingRiskMatrix, Plot_Pheno_Dates_DB_BB, PlotHistogram, Plot_Freeze_Risk, Plot_Freeze_Risk_sample, Plot_Freeze_Risk_Bar
#P.S : Each function has to be documented in index.md

include("PhenoPred.jl")
include("Prev2.jl")

end


# import Pkg
# cd(@__DIR__)
# Pkg.activate("..")
# Pkg.status()]