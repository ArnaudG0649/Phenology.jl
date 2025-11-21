module Phenology

export AppleModel, BRIN_Model, Apple_Phenology_Pred, Vine_Phenology_Pred, FreezingRisk, FreezingRiskMatrix, Plot_Pheno_Dates_EB_BB, PlotHistogram, Plot_Freeze_Risk, Plot_Freeze_Risk_sample, Plot_Freeze_Risk_Bar, extract_series, Common_indexes, Pred_n
export Take_temp_year, Iyear_CPO
#P.S : Each function with """....""" has to be documented in index.md unless checkdocs=:none
export Rc, Rf

include("table_reader.jl")
include("actions_loop.jl")
include("freezing_risk.jl")
include("species/apple.jl")
include("species/grapevine.jl")


function Plot_Pheno_Dates_EB_BB end
function PlotHistogram end
function Plot_Freeze_Risk end
function Plot_Freeze_Risk_sample end
function Plot_Freeze_Risk_Bar end

end


# import Pkg
# cd(@__DIR__)
# Pkg.activate("..")
# Pkg.status()]