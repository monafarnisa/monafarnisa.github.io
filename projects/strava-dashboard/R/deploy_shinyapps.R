#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(rsconnect)
})

# Optional local secrets file (gitignored).
if (file.exists("keys.R")) {
  source("keys.R", local = .GlobalEnv)
}

required <- c("SHINYAPPS_ACCOUNT", "SHINYAPPS_TOKEN", "SHINYAPPS_SECRET")
missing_vars <- required[!nzchar(Sys.getenv(required))]

if (length(missing_vars) > 0) {
  stop(
    "Missing required environment variables: ",
    paste(missing_vars, collapse = ", "),
    call. = FALSE
  )
}

account <- Sys.getenv("SHINYAPPS_ACCOUNT")
token <- Sys.getenv("SHINYAPPS_TOKEN")
secret <- Sys.getenv("SHINYAPPS_SECRET")
app_name <- Sys.getenv("SHINYAPPS_APP_NAME", unset = "mona-strava-dashboard")

rsconnect::setAccountInfo(
  name = account,
  token = token,
  secret = secret
)

rsconnect::deployApp(
  appDir = ".",
  appName = app_name,
  appTitle = "Mona Strava Dashboard",
  launch.browser = FALSE
)

cat(
  paste0(
    "Deployed URL: https://", account,
    ".shinyapps.io/", app_name, "/\n"
  )
)
