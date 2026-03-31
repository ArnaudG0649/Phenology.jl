#### IMPORTANT : translate the plot functions to the CairoMakie syntax or create an extension for PlotlyJS ####  

function Plot_hester(results_df::DataFrame)
    plot1 = plot(
        [
            scatter(x=results_df.date, y=results_df.wl, name="wl", mode="lines"),
            scatter(x=results_df.date, y=results_df.ww, name="ww", mode="lines"),
            scatter(x=results_df.date, y=results_df.wf, name="wf", mode="lines"),
            scatter(x=results_df.date, y=results_df.wr, name="wr", mode="lines")
        ],
        Layout(
            title="Biomasses evolution (wl, ww, wf, wr)",
            xaxis_title="Date",
            yaxis_title="Biomass",
            hovermode="x unified"
        )
    )
    # Plot 2: Proportions (ρl, ρw, ρf, ρr)
    plot2 = plot(
        [
            scatter(x=results_df.date, y=results_df.ρl, name="ρl", mode="lines"),
            scatter(x=results_df.date, y=results_df.ρw, name="ρw", mode="lines"),
            scatter(x=results_df.date, y=results_df.ρf, name="ρf", mode="lines"),
            scatter(x=results_df.date, y=results_df.ρr, name="ρr", mode="lines")
        ],
        Layout(
            title="Proportions evolution (ρl, ρw, ρf, ρr)",
            xaxis_title="Date",
            yaxis_title="Proportion",
            hovermode="x unified"
        )
    )

    # Plot 3: LA (Leaf Area)
    plot3 = plot(
        scatter(x=results_df.date, y=results_df.LA, name="LA", mode="lines", line=attr(color="green")),
        Layout(
            title="Leaf area evolution (LA)",
            xaxis_title="Date",
            yaxis_title="LA",
            hovermode="x unified"
        )
    )

    # Plot 4: P (Photosynthesis)
    plot4 = plot(
        scatter(x=results_df.date, y=results_df.P, name="P", mode="lines", line=attr(color="blue")),
        Layout(
            title="Photosynthesis evolution (P)",
            xaxis_title="Date",
            yaxis_title="P",
            hovermode="x unified"
        )
    )
    return plot1, plot2, plot3, plot4
end

function Hester_collect(Result_dict)
    year_vec = keys(Result_dict)
    wtot_vec = map(df -> df.ww[end] + df.wr[end], values(Result_dict))
    wf_vec = map(df -> df.wf[end], values(Result_dict))
    ρf_vec = map(df -> df.ρf[end], values(Result_dict))
    LA_vec = map(df -> df.LA[end], values(Result_dict))
    P_vec = map(df -> maximum(df.P), values(Result_dict))
    return year_vec, wtot_vec, wf_vec, ρf_vec, LA_vec, P_vec
end

function Plot_hester(year_vec, wtot_vec, wf_vec, ρf_vec, LA_vec, P_vec, GA_vec)
    plot5 = plot(
        scatter(x=year_vec, y=wtot_vec, name="wtot", mode="lines", line=attr(color="black")),
        Layout(
            title="Total mass",
            xaxis_title="Year",
            yaxis_title="wtot",
            hovermode="x unified"
        )
    )

    plot6 = plot(
        scatter(x=year_vec, y=wf_vec, name="wf", mode="lines", line=attr(color="blue")),
        Layout(
            title="Fruit mass",
            xaxis_title="Year",
            yaxis_title="wf_vec",
            hovermode="x unified"
        )
    )

    plot7 = plot(
        scatter(x=year_vec, y=ρf_vec, name="ρf", mode="lines", line=attr(color="red")),
        Layout(
            title="Fruit proportion",
            xaxis_title="Year",
            yaxis_title="ρf",
            hovermode="x unified"
        )
    )

    plot8 = plot(
        scatter(x=year_vec, y=LA_vec, name="LA", mode="lines", line=attr(color="blue")),
        Layout(
            title="Leaf area",
            xaxis_title="Year",
            yaxis_title="LA",
            hovermode="x unified"
        )
    )

    plot9 = plot(
        scatter(x=year_vec, y=P_vec, name="P", mode="lines", line=attr(color="green")),
        Layout(
            title="Yearly max photosynthesis",
            xaxis_title="Year",
            yaxis_title="P",
            hovermode="x unified"
        )
    )

    plot10 = plot(
        scatter(x=year_vec, y=GA_vec, name="GA", mode="lines", line=attr(color="blue")),
        Layout(
            title="Ground area",
            xaxis_title="Year",
            yaxis_title="GA",
            hovermode="x unified"
        )
    )
    return plot5, plot6, plot7, plot8, plot9, plot10
end
Plot_hester(Result_dict::OrderedDict, GA_vec) = Plot_hester([collect(Hester_collect(Result_dict)); [GA_vec]]...)

