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

In R:

```r
install.packages(c(
  "shiny", "shinydashboard", "dplyr", "lubridate",
  "ggplot2", "plotly", "leaflet", "DT", "rStrava", "httr"
))
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

## 3) Pull your Strava data

From this directory:

```bash
Rscript R/fetch_strava_data.R
```

This generates `data/activities.rds`.

## 4) Run the dashboard locally

```bash
R -e "shiny::runApp('.')"
```

## 5) Deploy and embed on your professional website

Deploy with Posit Connect or shinyapps.io, then update your site iframe URL in:

- `docs/professional/index.html`

Replace the placeholder:

- `https://your-shinyapps-url-here`
