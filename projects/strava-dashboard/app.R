library(shiny)
library(shinydashboard)
library(dplyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(leaflet)
library(DT)

load_activities <- function(path = "data/activities.rds") {
  if (file.exists(path)) {
    return(readRDS(path))
  }

  set.seed(42)
  dates <- seq.Date(as.Date("2024-01-01"), Sys.Date(), by = "day")
  sampled_dates <- sample(dates, 280, replace = TRUE)
  tibble(
    id = seq_len(length(sampled_dates)),
    name = paste("Activity", seq_len(length(sampled_dates))),
    start_date_local = sampled_dates,
    sport_type = sample(c("Ride", "Run", "Hike", "Walk"), length(sampled_dates), replace = TRUE),
    total_miles = round(rlnorm(length(sampled_dates), log(8), 0.45), 2),
    elevation_gain_ft = round(rlnorm(length(sampled_dates), log(700), 0.6), 0),
    moving_time_sec = round(total_miles * runif(length(sampled_dates), 420, 720)),
    lat = runif(length(sampled_dates), 32.5, 45.5),
    lng = runif(length(sampled_dates), -124.5, -111.0),
    gear_name = sample(
      c("Road Bike", "Gravel Bike", "Trail Shoes", "Road Shoes", "Hiking Boots"),
      length(sampled_dates),
      replace = TRUE
    )
  ) %>%
    mutate(
      avg_pace_min_mile = round((moving_time_sec / 60) / pmax(total_miles, 0.1), 2),
      year = year(start_date_local)
    )
}

activities <- load_activities()

if (!"year" %in% names(activities)) {
  activities$year <- year(as.Date(activities$start_date_local))
}

if (!"avg_pace_min_mile" %in% names(activities) && "moving_time_sec" %in% names(activities)) {
  activities$avg_pace_min_mile <- round((activities$moving_time_sec / 60) / pmax(activities$total_miles, 0.1), 2)
}

ui <- dashboardPage(
  dashboardHeader(title = "My Strava Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("chart-line")),
      menuItem("Map & Gear", tabName = "map_gear", icon = icon("map")),
      menuItem("Data", tabName = "data", icon = icon("table"))
    ),
    dateRangeInput(
      "date_range",
      "Date range",
      start = min(as.Date(activities$start_date_local), na.rm = TRUE),
      end = max(as.Date(activities$start_date_local), na.rm = TRUE)
    ),
    checkboxGroupInput(
      "sports",
      "Sport types",
      choices = sort(unique(activities$sport_type)),
      selected = sort(unique(activities$sport_type))
    ),
    sliderInput(
      "distance_range",
      "Distance range (miles)",
      min = floor(min(activities$total_miles, na.rm = TRUE)),
      max = ceiling(max(activities$total_miles, na.rm = TRUE)),
      value = c(
        floor(min(activities$total_miles, na.rm = TRUE)),
        ceiling(max(activities$total_miles, na.rm = TRUE))
      ),
      step = 1
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .small-box h3 { font-size: 1.6rem; }
        .box-title { font-weight: 600; }
      "))
    ),
    tabItems(
      tabItem(
        tabName = "overview",
        fluidRow(
          valueBoxOutput("total_activities", width = 3),
          valueBoxOutput("total_distance", width = 3),
          valueBoxOutput("total_elevation", width = 3),
          valueBoxOutput("active_days", width = 3)
        ),
        fluidRow(
          box(
            width = 7,
            title = "Distance over time",
            status = "primary",
            solidHeader = TRUE,
            plotlyOutput("distance_ts", height = 320)
          ),
          box(
            width = 5,
            title = "Sport type distribution",
            status = "info",
            solidHeader = TRUE,
            plotlyOutput("sport_type_bar", height = 320)
          )
        ),
        fluidRow(
          box(
            width = 12,
            title = "Elevation gain vs distance",
            status = "warning",
            solidHeader = TRUE,
            plotlyOutput("elev_dist_scatter", height = 320)
          )
        )
      ),
      tabItem(
        tabName = "map_gear",
        fluidRow(
          box(
            width = 8,
            title = "Activity start points",
            status = "primary",
            solidHeader = TRUE,
            leafletOutput("activity_map", height = 500)
          ),
          box(
            width = 4,
            title = "Gear mileage",
            status = "success",
            solidHeader = TRUE,
            plotlyOutput("gear_mileage", height = 500)
          )
        )
      ),
      tabItem(
        tabName = "data",
        fluidRow(
          box(
            width = 12,
            title = "Filtered activity table",
            status = "primary",
            solidHeader = TRUE,
            DTOutput("activity_table")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  filtered <- reactive({
    activities %>%
      mutate(start_date_local = as.Date(start_date_local)) %>%
      filter(
        start_date_local >= as.Date(input$date_range[1]),
        start_date_local <= as.Date(input$date_range[2]),
        sport_type %in% input$sports,
        total_miles >= input$distance_range[1],
        total_miles <= input$distance_range[2]
      )
  })

  output$total_activities <- renderValueBox({
    valueBox(format(nrow(filtered()), big.mark = ","), "Activities", icon = icon("bicycle"), color = "aqua")
  })

  output$total_distance <- renderValueBox({
    miles <- round(sum(filtered()$total_miles, na.rm = TRUE), 1)
    valueBox(paste0(format(miles, big.mark = ","), " mi"), "Distance", icon = icon("road"), color = "green")
  })

  output$total_elevation <- renderValueBox({
    elev <- round(sum(filtered()$elevation_gain_ft, na.rm = TRUE), 0)
    valueBox(paste0(format(elev, big.mark = ","), " ft"), "Elevation gain", icon = icon("mountain"), color = "yellow")
  })

  output$active_days <- renderValueBox({
    days <- n_distinct(filtered()$start_date_local)
    valueBox(format(days, big.mark = ","), "Active days", icon = icon("calendar"), color = "purple")
  })

  output$distance_ts <- renderPlotly({
    by_day <- filtered() %>%
      group_by(start_date_local) %>%
      summarise(total_miles = sum(total_miles, na.rm = TRUE), .groups = "drop")

    p <- ggplot(by_day, aes(start_date_local, total_miles)) +
      geom_line(color = "#1f78b4", linewidth = 0.8) +
      geom_smooth(se = FALSE, method = "loess", color = "#33a02c", linewidth = 0.8) +
      labs(x = NULL, y = "Miles", caption = "Daily total distance") +
      theme_minimal(base_size = 12)

    ggplotly(p, tooltip = c("x", "y"))
  })

  output$sport_type_bar <- renderPlotly({
    by_type <- filtered() %>%
      count(sport_type, sort = TRUE)

    p <- ggplot(by_type, aes(x = reorder(sport_type, n), y = n, fill = sport_type)) +
      geom_col(show.legend = FALSE) +
      coord_flip() +
      labs(x = NULL, y = "Activities") +
      theme_minimal(base_size = 12)

    ggplotly(p, tooltip = c("x", "y"))
  })

  output$elev_dist_scatter <- renderPlotly({
    p <- ggplot(
      filtered(),
      aes(x = total_miles, y = elevation_gain_ft, color = sport_type, text = name)
    ) +
      geom_point(alpha = 0.7, size = 2) +
      labs(x = "Distance (miles)", y = "Elevation gain (ft)", color = "Sport type") +
      theme_minimal(base_size = 12)

    ggplotly(p, tooltip = c("text", "x", "y", "colour"))
  })

  output$activity_map <- renderLeaflet({
    dat <- filtered() %>% filter(!is.na(lat), !is.na(lng))
    req(nrow(dat) > 0)

    pal <- colorFactor("Set2", domain = dat$sport_type)
    leaflet(dat) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~lng,
        lat = ~lat,
        radius = 5,
        color = ~pal(sport_type),
        stroke = FALSE,
        fillOpacity = 0.7,
        popup = ~paste0(
          "<b>", name, "</b><br/>",
          "Type: ", sport_type, "<br/>",
          "Distance: ", total_miles, " mi<br/>",
          "Elevation: ", elevation_gain_ft, " ft"
        )
      ) %>%
      addLegend("bottomright", pal = pal, values = ~sport_type, title = "Sport type")
  })

  output$gear_mileage <- renderPlotly({
    gear <- filtered() %>%
      filter(!is.na(gear_name), gear_name != "") %>%
      group_by(gear_name) %>%
      summarise(total_miles = sum(total_miles, na.rm = TRUE), .groups = "drop") %>%
      arrange(desc(total_miles))

    req(nrow(gear) > 0)
    p <- ggplot(gear, aes(x = reorder(gear_name, total_miles), y = total_miles)) +
      geom_col(fill = "#6a3d9a") +
      coord_flip() +
      labs(x = NULL, y = "Miles") +
      theme_minimal(base_size = 12)

    ggplotly(p, tooltip = c("x", "y"))
  })

  output$activity_table <- renderDT({
    filtered() %>%
      select(
        start_date_local, name, sport_type, total_miles, elevation_gain_ft,
        avg_pace_min_mile, gear_name
      ) %>%
      arrange(desc(start_date_local)) %>%
      datatable(
        filter = "top",
        options = list(pageLength = 15, scrollX = TRUE),
        rownames = FALSE
      )
  })
}

shinyApp(ui, server)
