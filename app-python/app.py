from dash import Dash, dcc, html, Input, Output
import dash_bootstrap_components as dbc
import polars as pl
import plotly.graph_objects as go

# Initialize with Bootstrap theme
app = Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP])

# Read the parquet file
us_counties = pl.read_parquet("data/us_counties.parquet")

# Get unique states for dropdown
all_states = us_counties.select("state").unique().sort("state").to_series().to_list()

# Custom CSS for theming to match Quarto dashboard
app.index_string = '''
<!DOCTYPE html>
<html>
    <head>
        {%metas%}
        <title>{%title%}</title>
        {%favicon%}
        {%css%}
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@300;400;600;700&display=swap');

            body {
                font-family: 'Open Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background-color: #ffffff;
            }

            .custom-header {
                background: linear-gradient(135deg, #0357b8 0%, #5b9bd5 100%);
                color: white;
                padding: 1.5rem;
                margin-bottom: 2rem;
                border-bottom: 3px solid #0357b8;
            }

            .custom-card {
                background-color: #ffffff;
                border: 1px solid #d4e6f1;
                border-radius: 8px;
                box-shadow: 0 2px 6px rgba(0,0,0,0.08);
            }

            .Select-control {
                border-color: #d4e6f1 !important;
                border-radius: 6px !important;
            }

            .Select-control:focus {
                border-color: #0357b8 !important;
                box-shadow: 0 0 0 0.2rem rgba(3, 87, 184, 0.15) !important;
            }
        </style>
    </head>
    <body>
        {%app_entry%}
        <footer>
            {%config%}
            {%scripts%}
            {%renderer%}
        </footer>
    </body>
</html>
'''

app.layout = dbc.Container([
    # Header
    dbc.Row([
        dbc.Col([
            html.Div([
                html.H1("Access to Hospital Care",
                       style={"fontWeight": "600", "marginBottom": "0.5rem"}),
                html.P("Analyze hospital distribution and predictions across US counties",
                      style={"marginBottom": "0", "opacity": "0.9"})
            ], className="custom-header")
        ])
    ]),

    # Controls Card
    dbc.Row([
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    html.Label("Select State:",
                              style={"fontWeight": "600", "color": "#2c3e50", "marginBottom": "0.5rem"}),
                    dcc.Dropdown(
                        id="state",
                        options=[{"label": i, "value": i} for i in all_states],
                        value="CA",
                        style={"marginBottom": "0"}
                    ),
                ])
            ], className="custom-card mb-4")
        ], width=12)
    ]),

    # Graph Card
    dbc.Row([
        dbc.Col([
            dbc.Card([
                dbc.CardBody([
                    dcc.Loading(
                        id="loading",
                        type="default",
                        children=html.Div(id="counties"),
                        color="#0357b8"
                    )
                ])
            ], className="custom-card")
        ], width=12)
    ])
], fluid=True, style={"maxWidth": "1400px", "padding": "2rem"})

@app.callback(
    Output("counties", "children"),
    Input("state", "value")
)
def update_counties(value):
    # Filter counties by selected state
    st_counties = us_counties.filter(pl.col("state") == value)

    # Map pred_status to colors - matching other assets
    color_map = {"below": "#CC79A7", "ok": "#009E73", "above": "#0072B2"}
    counties_df = st_counties.with_columns(
        pl.col("pred_status").replace(color_map).alias("color")
    )

    # Calculate dynamic height based on number of counties
    num_counties = counties_df.height
    chart_height = max(600, min(num_counties * 25, 2000))

    # Create figure with improved styling
    fig = go.Figure()

    # Add actual hospitals trace
    fig.add_trace(go.Scatter(
        x=counties_df["hospitals"].to_list(),
        y=counties_df["county_name"].to_list(),
        mode="markers",
        name="Actual Hospitals",
        marker=dict(
            color=counties_df["color"].to_list(),
            size=12,
            line=dict(width=1, color='white')
        ),
        hovertemplate="<b>%{y}</b><br>Hospitals: %{x}<extra></extra>"
    ))

    # Add predicted hospitals trace
    fig.add_trace(go.Scatter(
        x=counties_df["pred_fit"].to_list(),
        y=counties_df["county_name"].to_list(),
        mode="markers",
        name="Expected",
        marker=dict(
            color="#2c3e50",
            size=8,
            symbol="diamond"
        ),
        hovertemplate="<b>%{y}</b><br>Expected: %{x:.1f}<extra></extra>"
    ))

    # Add minimum threshold trace
    fig.add_trace(go.Scatter(
        x=counties_df["pred_lwr"].to_list(),
        y=counties_df["county_name"].to_list(),
        mode="markers",
        name="Minimum Expected",
        marker=dict(
            color="#cccccc",
            size=6,
            symbol="x"
        ),
        hovertemplate="<b>%{y}</b><br>Minimum: %{x:.1f}<extra></extra>"
    ))

    # Update layout with theme colors
    fig.update_layout(
        height=chart_height,
        margin=dict(l=200, r=20, t=60, b=60),
        xaxis=dict(
            title=dict(
                text="Number of Hospitals",
                font=dict(size=14, color="#2c3e50", family="Open Sans")
            ),
            gridcolor="#e8f4fd",
            zerolinecolor="#d4e6f1"
        ),
        yaxis=dict(
            title="",
            tickfont=dict(size=11, color="#2c3e50", family="Open Sans")
        ),
        plot_bgcolor="white",
        paper_bgcolor="white",
        font=dict(family="Open Sans", color="#2c3e50"),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="right",
            x=1,
            bgcolor="rgba(255,255,255,0.8)",
            bordercolor="#d4e6f1",
            borderwidth=1
        ),
        hovermode="closest"
    )

    return dcc.Graph(
        id="counties_plot",
        figure=fig,
        config={'displayModeBar': True, 'displaylogo': False}
    )

if __name__ == "__main__":
    app.run(debug=True)
