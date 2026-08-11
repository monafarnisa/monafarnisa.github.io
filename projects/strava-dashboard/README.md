# Personal Strava Shiny Dashboard

This project is a personal Strava dashboard inspired by Sam Csik's dashboard app architecture and feature set.

Reference inspiration:
- https://samanthacsik.shinyapps.io/strava_dashboard/
- https://github.com/samanthacsik/strava-dashboard

## What this app includes

- Sidebar filters for date range, sport type, and distance
- KPI cards (activities, distance, elevation, active days)
- Distance time series and sport type activity distribution
- Elevation vs distance scatter plot
- Interactive leaflet map of activity start points
- Gear mileage chart
- Filterable data table

## 1) Install dependencies

In this project, dependencies are installed into a local library folder (`.Rlib`):

```bash
mkdir -p .Rlib
Rscript -e ".libPaths(c(normalizePath('.Rlib'), .libPaths())); install.packages(c('shiny','shinydashboard','dplyr','lubridate','ggplot2','plotly','leaflet','DT','rStrava','httr','rsconnect'), repos='https://cloud.r-project.org', type='binary')"
```

## 2) Configure Strava API credentials

Create a Strava API app in your Strava account, then set:

- `STRAVA_APP_NAME`
- `STRAVA_CLIENT_ID`
- `STRAVA_CLIENT_SECRET`

Example in terminal:

```bash
export STRAVA_APP_NAME="your_app_name"
export STRAVA_CLIENT_ID="your_client_id"
export STRAVA_CLIENT_SECRET="your_client_secret"
```

Alternative (your preferred workflow): create a local `keys.R` file and keep it out of git.

```bash
cp keys.example.R keys.R
```

Then edit `keys.R` with your real values. Both `R/fetch_strava_data.R` and
`R/deploy_shinyapps.R` will auto-source `keys.R` if it exists.

## 3) Pull your Strava data

From this directory:

```bash
Rscript -e ".libPaths(c(normalizePath('.Rlib'), .libPaths())); source('R/fetch_strava_data.R')"
```

This generates `data/activities.rds`.

## 4) Run the dashboard locally

```bash
Rscript -e ".libPaths(c(normalizePath('.Rlib'), .libPaths())); shiny::runApp('.', port = 4242)"
```

## 5) Deploy to shinyapps.io

Set your shinyapps.io publishing credentials:

- `SHINYAPPS_ACCOUNT`
- `SHINYAPPS_TOKEN`
- `SHINYAPPS_SECRET`
- optional: `SHINYAPPS_APP_NAME` (defaults to `mona-strava-dashboard`)

```bash
export SHINYAPPS_ACCOUNT="your_account_name"
export SHINYAPPS_TOKEN="your_token"
export SHINYAPPS_SECRET="your_secret"
export SHINYAPPS_APP_NAME="mona-strava-dashboard"
Rscript -e ".libPaths(c(normalizePath('.Rlib'), .libPaths())); source('R/deploy_shinyapps.R')"
```

## 6) Embed on your professional website

Deploy with Posit Connect or shinyapps.io, then update your site iframe URL in:

- `docs/professional/index.html`

Replace the placeholder:

- `https://your-shinyapps-url-here`
