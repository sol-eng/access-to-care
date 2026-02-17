from fastapi import FastAPI, HTTPException
import polars as pl
from typing import Optional

app = FastAPI(
    title="Access to Care API",
    description="REST API providing access to hospital and population data across US counties and states",
    version="1.0.0"
)

# Load data at startup
us_counties = pl.read_parquet("data/us_counties.parquet")
us_states = pl.read_parquet("data/us_states.parquet")


@app.get("/")
async def root():
    """
    Root endpoint providing API documentation and available endpoints.
    """
    return {
        "name": "Access to Care API",
        "version": "1.0.0",
        "description": "REST API for accessing hospital and population data across US counties and states",
        "endpoints": {
            "/": {
                "method": "GET",
                "description": "API documentation (this endpoint)"
            },
            "/state": {
                "method": "GET",
                "description": "Get county-level data for a specific state",
                "parameters": {
                    "state": {
                        "type": "string",
                        "description": "Two-letter state abbreviation (e.g., 'CA', 'NY', 'TX')",
                        "default": "MS"
                    }
                },
                "returns": "List of counties with population, hospitals, and prediction status"
            },
            "/summary": {
                "method": "GET",
                "description": "Get summary statistics for a specific state",
                "parameters": {
                    "state": {
                        "type": "string",
                        "description": "Two-letter state abbreviation (e.g., 'CA', 'NY', 'TX')",
                        "default": "MS"
                    }
                },
                "returns": "State-level summary with total counties, population, and hospitals"
            }
        },
        "examples": {
            "state": "/state?state=CA",
            "summary": "/summary?state=NY"
        }
    }


@app.get("/state")
async def get_state(state: str = "MS"):
    """
    Get county-level data for a specific state.

    Parameters:
    - state: Two-letter state abbreviation (default: "MS")

    Returns:
    - List of counties with their data including:
      - county_name: Name of the county
      - state: State abbreviation
      - hospitals: Number of hospitals
      - population: County population
      - pred_status: Model prediction status (below/ok/above)
    """
    st_name = state.upper()

    # Filter counties by state
    state_counties = us_counties.filter(pl.col("state") == st_name)

    # Check if state exists
    if state_counties.height == 0:
        raise HTTPException(
            status_code=404,
            detail=f"State '{state}' not found. Please provide a valid two-letter state abbreviation."
        )

    # Select relevant columns
    st_cols = ["county_name", "state", "hospitals", "population", "pred_status"]
    result = state_counties.select(st_cols)

    # Convert to list of dictionaries for JSON response
    return result.to_dicts()


@app.get("/summary")
async def get_summary(state: str = "MS"):
    """
    Get summary statistics for a specific state.

    Parameters:
    - state: Two-letter state abbreviation (default: "MS")

    Returns:
    - State summary including:
      - state: State abbreviation
      - state_name: Full state name
      - counties: Number of counties
      - population: Total state population
      - hospitals: Total number of hospitals
      - counties_below: Number of underserved counties
      - counties_ok: Number of adequately served counties
      - counties_above: Number of overserved counties
    """
    st_name = state.upper()

    # Filter states by state code
    state_data = us_states.filter(pl.col("state") == st_name)

    # Check if state exists
    if state_data.height == 0:
        raise HTTPException(
            status_code=404,
            detail=f"State '{state}' not found. Please provide a valid two-letter state abbreviation."
        )

    # Convert to dictionary for JSON response
    result = state_data.to_dicts()

    # Return first (and only) record
    return result[0] if result else {}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
