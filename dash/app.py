from dash import Dash, dcc, html, Input, Output
import polars as pl
import plotly.graph_objects as go

app = Dash(__name__, external_stylesheets=["dashboard"])

# Read the parquet file
us_counties = pl.read_parquet("data/us_counties.parquet")

# Get unique states for dropdown
all_states = us_counties.select("state").unique().sort("state").to_series().to_list()

app.layout = html.Div(children=[
    html.H1(children= ["Access to Hospital Care"]),

    dcc.Dropdown(
        id="state",
        options=[{"label": i, "value": i} for i in all_states],
        value = "CA"
    ),
    html.Div(id="counties")
])

@app.callback(
    Output("counties", "children"),
    Input("state", "value")
)
def update_counties(value):
    # Filter counties by selected state
    st_counties = us_counties.filter(pl.col("state") == value)

    # Map pred_status to colors
    color_map = {"below": "#d62728", "ok": "#2ca02c", "above": "#1f77b4"}
    counties_df = st_counties.with_columns(
        pl.col("pred_status").map_dict(color_map).alias("color")
    )

    fig_layout = go.Layout(
        height = 2000
    )
    fig2 = go.Figure(layout = fig_layout)
    fig2.add_trace(go.Scatter(
                    x = counties_df["hospitals"].to_list(),
                    y = counties_df["county_name"].to_list(),
                    mode = "markers",
                    name = "Hospitals",
                    marker_color = counties_df["color"].to_list(),
                    marker = dict(size = 20)
                    ))
    fig2.add_trace(go.Scatter(
                    x = counties_df["pred_fit"].to_list(),
                    y = counties_df["county_name"].to_list(),
                    mode = "markers",
                    name = "Predicted",
                    marker_color = "#333333",
                    marker = dict(size = 10)
                    ))
    fig2.add_trace(go.Scatter(
                    x = counties_df["pred_lwr"].to_list(),
                    y = counties_df["county_name"].to_list(),
                    mode = "markers",
                    name = "Minimum",
                    marker_color = "#dddddd",
                    marker = dict(size = 10)
                    ))
    return dcc.Graph(id="counties_plot", figure=fig2)

if __name__ == "__main__":
    app.run(debug=True)
