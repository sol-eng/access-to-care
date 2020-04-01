import dash
import dash_core_components as dcc
import dash_html_components as html
import dash_bootstrap_components as dbc
from dash.dependencies import Input, Output

import pandas as pd
import requests 

app = dash.Dash(__name__, external_stylesheets=[dbc.themes.BOOTSTRAP])

text_style = dict(textAlign='center', color='#4D8DC9', fontFamily='sans-serif', fontWeight=300)

colors = {
    'background': '#F8F8F8',
    'text': '#404040',
    'accent': '#E7553C',
    'darkblue': '#447099'
}

RSTUDIO_LOGO = "https://d33wubrfki0l68.cloudfront.net/1ac3f0e3753f18c7e2a8893957d1841fba1e3d08/48a33/wp-content/uploads/2018/10/rstudio-logo-flat.png"


search_bar = dbc.Row(
    [
        dbc.Input(id="state", value="NY", type="text"),
    ],
    no_gutters=True,
    className="ml-auto flex-nowrap mt-3 mt-md-0",
    align="center",
)

app.layout = html.Div(style={'backgroundColor': colors['background']}, children=[

    dbc.Navbar(
    [
        html.A(
            # Use row and col to control vertical alignment of logo / brand
            dbc.Row(
                [
                    dbc.Col(html.Img(src=RSTUDIO_LOGO, height="30px")),
                    dbc.Col(dbc.NavbarBrand("Access to Hospital Care", className="ml-2")),
                ],
                align="center",
                no_gutters=True,
            ),
            href="https://solutions.rstudio.com/",
        ),
        dbc.Collapse(search_bar, navbar=True),
    ],
    color="#447099",
    dark=True,
    ),

    html.Div(id="summary"),
    html.Div(id="counties")
    #dbc.Table.from_dataframe(counties, id='counties', striped=True, bordered=True, hover=True)
    
])

@app.callback(
    Output("summary","children"),
    [Input("state","value")]
)
def update_summary(value):
    st_summary = requests.get('https://colorado.rstudio.com/rsc/access-to-care/api/summary?state=' + value)
    summary =  pd.DataFrame.from_dict(st_summary.json())
    return dbc.Table.from_dataframe(summary, dark=True, striped=True, bordered=True, hover=True)

@app.callback(
    Output("counties","children"),
    [Input("state","value")]
)
def update_counties(value):
    st_detail = requests.get('https://colorado.rstudio.com/rsc/access-to-care/api/state?state=' + value)
    counties = pd.DataFrame.from_dict(st_detail.json())
    return dbc.Table.from_dataframe(counties, striped=True, bordered=True, hover=True)

if __name__ == '__main__':
    app.run_server(debug=True)