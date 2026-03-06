#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(rStrava)
  library(dplyr)
  library(lubridate)
})

# Optional local secrets file (gitignored).
if (file.exists("keys.R")) {
  source("keys.R", local = .GlobalEnv)
}

required <- c("STRAVA_APP_NAME", "STRAVA_CLIENT_ID", "STRAVA_CLIENT_SECRET")
missing_vars <- required[!nzchar(Sys.getenv(required))]
if (length(missing_vars) > 0) {
  stop(
    "Missing required environment variables: ",
    paste(missing_vars, collapse = ", "),
    call. = FALSE
  )
}

app_name <- Sys.getenv("STRAVA_APP_NAME")
client_id <- Sys.getenv("STRAVA_CLIENT_ID")
client_secret <- Sys.getenv("STRAVA_CLIENT_SECRET")

token <- httr::config(
  token = strava_oauth(
    app_name = app_name,
    app_client_id = client_id,
    app_secret = client_secret,
    app_scope = "activity:read_all",
    cache = TRUE
  )
)

message("Requesting activities from Strava API...")
acts_raw <- get_activity_list(stoken = token)

if (length(acts_raw) == 0) {
  stop("No activities were returned by the API.", call. = FALSE)
}

acts <- compile_activities(acts_raw) %>%
  mutate(
    start_date_local = as_date(start_date_local),
    total_miles = round(distance * 0.621371, 2),
    elevation_gain_ft = round(total_elevation_gain * 3.28084, 0),
    moving_time_sec = moving_time,
    avg_pace_min_mile = round((moving_time_sec / 60) / pmax(total_miles, 0.1), 2),
    year = year(start_date_local),
    gear_name = dplyr::coalesce(gear_id, "Unknown Gear"),
    lat = suppressWarnings(as.numeric(start_latlng1)),
    lng = suppressWarnings(as.numeric(start_latlng2))
  ) %>%
  select(
    id, name, start_date_local, year, sport_type, total_miles, elevation_gain_ft,
    moving_time_sec, avg_pace_min_mile, gear_name, lat, lng
  ) %>%
  filter(!is.na(start_date_local))

dir.create("data", recursive = TRUE, showWarnings = FALSE)
saveRDS(acts, "data/activities.rds")

message("Saved ", nrow(acts), " activities to data/activities.rds")
