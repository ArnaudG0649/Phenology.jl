using Phenology
using JLD2, FileIO
using DataFrames, DataFramesMeta
using CairoMakie #PlotlyJS
using Dates
using OrderedCollections

#### IMPORTANT : translate the plot functions to the CairoMakie syntax or create an extension for PlotlyJS ####  

ind(date_vec, date1, date2) = findfirst(date_vec .== date1):findfirst(date_vec .== date2)
ind(date_vec, date) = findfirst(date_vec .== date):length(date_vec)

include("hester.jl")
include("daylength.jl")
include("plot.jl")

consider_ripening = true
ripening_time = 155

F1_Gold_1 = AppleModel((10, 30),
    TriangularAction(1.1, 20.),
    56.,
    ExponentialAction(9.),
    83.58)

df = extract_series(joinpath("..","stations","TG_Montpellier.txt"))
# x, date_vec = df.TG, df.DATE
# CPO = AppleModel().CPO
CPO = (10, 30)

Index = ind(df.DATE, Date(2000, CPO[1], CPO[2]), Date(2001, CPO[1], CPO[2]))

sx, sdate_vec = df.TG[Index], df.DATE[Index]
# pred = Apple_Phenology_Pred(df.TG, df.DATE)
pred = Apple_Phenology_Pred(sx, sdate_vec, F1_Gold_1)
EB, BB, FB = pred[1][1], pred[2][1] - Day(14), pred[2][1]

# [repeat([pred[1][1]], 5);  pred[1]]

###IMPORTANT INFORMATION : TCSA converges around 22 yo with value 127cm² (0.0127m²)

Lat = 43.3314
Age = 30
GA = 10. #+ c'est grand - est le wf
wtot = 100E3
NF = 500
results_df = Hester_model(sx, sdate_vec, EB, BB, FB, wtot; Lat=Lat, CPO=CPO, Age=Age, GA=GA, NF=NF)
display.(Plot_hester(results_df))


x, date_vec = df.TG, df.DATE
pred2 = Apple_Phenology_Pred(x, date_vec)
EB_vec, BB_vec, FB_vec = pred2[1], pred2[2] .- Day(14), pred2[2]

n_burn = 20
NF, GA, wtot, Age = 500, 10, 5E5, 100
Result_dict, GA_vec = Hester_model(x, date_vec, EB_vec, BB_vec, FB_vec, wtot; CPO=CPO, Age=Age, NF=NF, GA=GA, n_pre_series=n_burn)
display.(Plot_hester(Result_dict, GA_vec))

NF2, GA2, wtot2, Age2 = 200, 5, 5E5, 50
Result_dict2, GA_vec2 = Hester_model(x, date_vec, EB_vec, BB_vec, FB_vec, wtot2; CPO=CPO, Age=Age2, NF=NF2, GA=GA2, n_pre_series=n_burn)
display.(Plot_hester(Result_dict2, GA_vec2))

println(unique(map(df -> (month(df.date[end]), day(df.date[end])), values(Result_dict))))


wf_vec = consider_ripening ? map(t -> @subset(t[1], :date .<= t[2] + Day(ripening_time)).wf[end], zip(collect(values(Result_dict))[n_burn+1:end], FB_vec)) : map(df -> df.wf[end], values(Result_dict))
wf_vec2 = consider_ripening ? map(t -> @subset(t[1], :date .<= t[2] + Day(ripening_time)).wf[end], zip(collect(values(Result_dict2))[n_burn+1:end], FB_vec)) : map(df -> df.wf[end], values(Result_dict2))
year_vec = keys(Result_dict)
year_vec2 = keys(Result_dict2)
trace_wf1 = scatter(x=year_vec, y=wf_vec, name="Model 1", mode="lines", line_color="blue")
trace_wf2 = scatter(x=year_vec2, y=wf_vec2, name="Model 2", mode="lines", line_color="red")
layout = Layout(
    title="Fruit mass",
    xaxis_title="Year",
    yaxis_title="wf",
    hovermode="x unified"
)
display(plot([trace_wf1, trace_wf2], layout))
compare_trace = [scatter(x=wf_vec[(n_burn+1):end], y=wf_vec2[(n_burn+1):end], mode="lines", line_color="blue")]
compare_layout = Layout(
    title="wf NF=$(NF), GA=$GA, wtot=$(wtot), Age=$Age vs wf2 NF=$(NF2), GA=$GA2, wtot=$(wtot2), Age=$Age2",
    xaxis_title="wf",
    yaxis_title="wf2",
    hovermode="x unified"
)
display(plot(compare_trace, compare_layout))
#With chosen solar radiation : 
# SR = Solar_radiation_approx.(43.3314, df.DATE)
# Result_dict2, GA_vec = Hester_model(df.TG, df.DATE, pred2[1], pred2[2], wtot; Solar_radiation=SR, CPO=(10, 30), Age=Age, NF=200, cNF=0, cGA=cGA, GA=GA)
# display.(Plot_hester(Result_dict, GA_vec))
# Result_dict==Result_dict2


#Adding/substracting temperatures to observe the impact
Traces = GenericTrace[]
color_vec = ["darkcyan", "blue", "darkgreen", "yellowgreen", "gold", "orange", "red", "darkred"]
for (ΔT, color) in zip([-4, -2, 0, 1, 2, 3, 4, 5], color_vec)
    pred = Apple_Phenology_Pred(x .+ ΔT, date_vec)
    Result_dict, _ = Hester_model(x .+ ΔT, date_vec, pred[1], pred[2] .- Day(14), pred[2], wtot; CPO=CPO, Age=Age, NF=NF, GA=GA, n_pre_series=n_burn)
    wf_vec = map(df -> df.wf[end], values(Result_dict))
    year_vec = keys(Result_dict)
    trace_wf = scatter(x=year_vec, y=wf_vec, name="ΔT = $(ΔT)", mode="lines", line_color=color)
    push!(Traces, trace_wf)
end
layout = Layout(
    title="Fruit mass",
    xaxis_title="Year",
    yaxis_title="wf_vec",
    hovermode="x unified"
)
plt = plot(Traces, layout)
savefig(plt, "Fruit_Mass_dif_temp.pdf", height=700, width=1100, scale=2)

n = 5
T_vec = x

plot(
    scatter(x=[New_date_vec; date_vec], y=[New_t_vec; T_vec], name="wf", mode="lines", line=attr(color="blue")),
    Layout()
)


dayofyear(Date(2001, 3, 1))

x
x .+ 2

pred = Vine_Phenology_Pred(x .+ 2, date_vec, model, bloom_dates=true)