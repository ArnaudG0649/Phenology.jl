using Phenology, JLD2,  DataFrames, DataFramesMeta, Dates, XLSX
df_koch = DataFrame(XLSX.readtable(joinpath(@__DIR__, "..", "BB_Koch.xlsx"), "Feuil1"))

df_koch_complete = @transform(df_koch, :complete_date = Date.(:year, :month, :day))

df_koch_complete[!, :n] = Dates.value.(df_koch_complete.complete_date .- Date.(df_koch_complete.year, 3, 31))

# préparation du tracé
using CairoMakie

# styles demandés (les clés en minuscules)
styles = Dict(
    "pinot gris" => (marker=:circle, color=:black),
    "pinot noir" => (marker=:circle, color=:blue),
    "silvancer" => (marker=:dtriangle, color=:darkgreen),
    "riesling" => (marker=:utriangle, color=:orange),
    "müller-thurgau" => (marker=:rect, color=:pink),
)

x_min, x_max = 1975, 2015
n_min, n_max = 0, 40

major_xticks = x_min:5:x_max
minor_xticks = x_min:x_max
major_yticks = n_min:5:n_max
minor_yticks = n_min:n_max

fig = Figure(size=(600, 400))
ax = Axis(fig[1, 1], xlabel="Year", ylabel="Days since Apr 1", title="n par année et par variété", yticks=major_yticks, xticks=major_xticks)

for x in minor_xticks
    lines!(ax, [x, x], [n_min, n_max]; color=(:gray), linewidth=0.5, linestyle=:dot, transparency=0.2)
end
for y in minor_yticks
    lines!(ax, [x_min, x_max], [y, y]; color=(:gray), linewidth=0.5, linestyle=:dot, transparency=0.2)
end

for g in collect(groupby(df_koch_complete, :Variety))[[5, 2, 1, 3, 4]]
    v = String(first(g[!, :Variety]))
    yrs = Int.(g.year)
    ns = Int.(g.n)
    key = lowercase(v)
    style = get(styles, key, (marker=:circle, color=:gray))
    lines!(ax, yrs, ns; color=style.color)
    scatter!(ax, yrs, ns; marker=style.marker, color=style.color, markersize=v == "Müller-Thurgau" ? 11 : 8, label=v)
end

axislegend(ax; position=:rt)
fig

save("plot_bb_koch.pdf", fig)

# df_koch_final = DataFrame(Date=df_koch_complete.complete_date,
# Year=df_koch_complete.year,
# Day_of_the_year=Dates.value.(df_koch_complete.complete_date .- Date.(df_koch_complete.year, 1, 1)) .+ 1,
# Variety=df_koch_complete.Variety)


# XLSX.writetable("Data_BB_Hainfeld.xlsx", df_koch_final)