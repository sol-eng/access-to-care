import dash
import dash_core_components as dcc
import dash_html_components as html
import plotly.express as px
import pandas as pd
import requests 
import plotly.graph_objects as go

from dash.dependencies import Input, Output

app = dash.Dash(__name__, external_stylesheets=["dashboard"])

all_states = ["AL", "MS", "CA", "NY", "SC", "CO", "VA"]

app.layout = html.Div(children=[
    html.H1(children= ["Access to Hospital Care", html.Img(src="assets/RStudio1.png")]),

    dcc.Dropdown(
        id="state",
        options=[{"label": i, "value": i} for i in all_states],
        value = "CA"
    ),
    html.Div(id="counties")
])

@app.callback(
    Output("counties","children"),
    [Input("state","value")]
)
def update_counties(value):
    st_counties = requests.get("https://colorado.rstudio.com/rsc/access-to-care/api/state?state=" + value)
    counties =  pd.DataFrame.from_dict(st_counties.json())
    #fig2 = px.scatter(counties, x="population", y="hospitals", color = "result")
    fig_layout = go.Layout(
        height = 2000
    )
    fig2 = go.Figure(layout = fig_layout)
    fig2.add_trace(go.Scatter(
                    x = counties["hospitals"], 
                    y = counties["county"],
                    mode = "markers",
                    name = "Hospitals",
                    marker_color = counties["color"],
                    marker = dict(size = 20)
                    ))
    fig2.add_trace(go.Scatter(
                    x = counties["fit"], 
                    y = counties["county"],
                    mode = "markers",
                    name = "Predicted",
                    marker_color = "#333333",
                    marker = dict(size = 10)
                    ))
    fig2.add_trace(go.Scatter(
                    x = counties["lwr"], 
                    y = counties["county"],
                    mode = "markers",
                    name = "Minimum",
                    marker_color = "#dddddd",
                    marker = dict(size = 10)
                    ))
    return dcc.Graph(id="counties_plot", figure=fig2)

if __name__ == "__main__":
    app.run_server(debug=True)
