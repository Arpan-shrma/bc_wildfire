---
title: "Wildfire distribution in B.C"
author: "Arpan"
date: "November 10, 2024"
format: html
execute: 
  embed-resources: true
---

## Aim of analysis

In this assignment, I have analyzed the wildfire distribution in B.C over time from 2012-2017, and compared that to the current data. I also determined what climate and environmental factors increase impact fire likelihood.

To do this, I took the following steps:

1.  Scraped the 2012-2017 data using methods used in class.
2.  Pulled temperature and elevation data for B.C using the `geodata` package. Crop and mask as needed.
3.  Visualize wildfires over time between 2012-2017 overtop a temperature raster.
4.  Use a maximum of two visualizations to answer the question: how do temperature/elevation impact fire occurence?
5.  How does the historical distribution (2012-2017) of wildfires differ from this year's (2024) wildfires?

## Libraries used

-   Tidyverse
-   Dplyr
-   readxl
-   lubridate
-   patchwork

```{r, echo=FALSE, results='hide'}
# Install necessary packages if not already installed
if (!require("pacman")) install.packages("pacman")
pacman::p_load(rvest,janitor, dplyr, ggplot2, sf, raster, sp, rgdal, tidyverse, geodata, gganimate, terra,leaflet)
```

```{r, echo=FALSE, results='hide'}
library(tidyverse)
library(dplyr)
library(janitor)
library(terra)
library(readxl)
library(lubridate)
library(patchwork)
library(rvest)
library(geodata)
library(leaflet)
library(ggplot2)
library(osmdata)
library(sf)
library(xml2)
library(gganimate)
library(shiny)
library(raster)

```

# Let's Begin

1.  Scraped the 2012-2017 data using methods used in class.

```{r, echo=FALSE, results='hide'}
url_historic <- "https://www2.gov.bc.ca/gov/content/safety/wildfire-status/about-bcws/wildfire-statistics"
url_current <- "https://www2.gov.bc.ca/gov/content/safety/wildfire-status/about-bcws/disclaimer"
```

<!--Webscrapping from url_historic for records of all substantial wildfires that B.C government has recorded for year of 2012 to 2017-->

<!--I have used read_html function to read the url and html_element funtion -->

```{r, echo=FALSE, results='hide'}
fire_html <- read_html(url_historic)
fire_html
```

```{r, echo=FALSE, results='hide'}
df_his_wildfire <- fire_html |> 
  html_element("table") |> 
  html_table()
```

```{r, echo=FALSE, results='hide'}
df_his_wildfire %>% head()
```

```{r, echo=FALSE, results='hide'}
## Dataset First View
df_his_wildfire |> head()
```

```{r, echo=FALSE, results='hide'}
#Dimensions of data (Rows, Columns)
dim(df_his_wildfire)

#  Number of Rows: 1108 and Number of Columns: 8
```

```{r, echo=FALSE, results='hide'}
df_his_wildfire <- janitor::clean_names(df_his_wildfire)
```

```{r, echo=FALSE, results='hide'}
# Renaming the columns for easier data exploration
colnames(df_his_wildfire)
```

```{r, echo=FALSE, results='hide'}
# Convert to Date type using the correct format
# Removing potential white spaces so there will be no error while converting data type of the column 
df_his_wildfire$discovery_date <- gsub(" ", "", df_his_wildfire$discovery_date)
df_his_wildfire$discovery_date <- as.Date(df_his_wildfire$discovery_date, format="%b%d,%Y")  #<------used this %b%d,%Y date format is "Jan 01, 2017" and removing whitespaces made them "jan01,2017"
# Create a new column 'discovery_month' from 'discovery_date' for further analysis
df_his_wildfire$discovery_month <- month(df_his_wildfire$discovery_date, label = TRUE, abbr = TRUE)
# View the changes
head(df_his_wildfire)
```

```{r, echo=FALSE, results='hide'}
#checking for data type of different variables
str(df_his_wildfire)
```

<!--Handling Duplicates-->

```{r, echo=FALSE, results='hide'}
# - Checking for duplicates in data frame 

# Count the total number of rows
total_rows <- nrow(df_his_wildfire)

# Count the number of unique rows
unique_rows <- nrow(df_his_wildfire %>% distinct())

# Calculate the number of duplicate rows
duplicate_rows <- total_rows - unique_rows

# Print the number of duplicate rows
print(paste("Number of duplicate rows:", duplicate_rows))

```

<!--There are no duplicate rows found in dataframe.-->

<!--### Handling NA values and cleaning columns-->

```{r, echo=FALSE, results='hide'}
### Handling NA values and cleaning columns

# Define a custom function to detect NA-like values
is_na_like <- function(x) {
  str_trim(x) == "" | x %in% c("NA", "N.A", "---", "--", "-", "n/a", "none", "null", "nan") | is.na(x)
}

# Count NA-like values and number of unique values column-wise
na_counts_and_unique <- df_his_wildfire %>%
  summarise(across(everything(), list(
    na_count = ~sum(is_na_like(.), na.rm = TRUE),
    unique_count = ~n_distinct(.)
  )))

# View the result
print(na_counts_and_unique)
```

<!--handling Coordinates (Longitude and Latitude) columns-->

```{r, echo=FALSE, results='hide'}
# Correct way to replace dots (if you want to remove dots, which might not be necessary)
df_his_wildfire$latitude <- gsub("\\.", "", df_his_wildfire$latitude)
df_his_wildfire$longitude <- gsub("\\.", "", df_his_wildfire$longitude)

# Now if you intend to replace spaces with dots:
df_his_wildfire$latitude <- gsub(" ", ".", df_his_wildfire$latitude)
df_his_wildfire$longitude <- gsub(" ", ".", df_his_wildfire$longitude)

# Check the changes
head(df_his_wildfire)
```

```{r, echo=FALSE, results='hide'}
df_his_wildfire$latitude <- as.numeric(df_his_wildfire$latitude)
df_his_wildfire$longitude <- as.numeric(df_his_wildfire$longitude)
head(df_his_wildfire)

```

<!--As this data is from Canada which is on northern hemisphere and western hemisphere.
Hence, latitude should be positive representing northern hemisphere and Longitude should be negative representing western hemisphere -->

```{r, echo=FALSE, results='hide'}
# Converting longitude values to negative 
# Correcting the signs based on the reasoning 
df_his_wildfire$latitude <- abs(df_his_wildfire$latitude)  # North, should be positive
df_his_wildfire$longitude <- -abs(df_his_wildfire$longitude)  # West, should be negative
head(df_his_wildfire$longitude)
```

```{r, echo=FALSE, results='hide'}
# Get the data types of each column
sapply(df_his_wildfire, class)
```

<!--2. Pulled temperature and elevation data for B.C using the `geodata` package. Crop and mask as needed.-->

```{r}
# Define the temporary directory for storing data
temp_dir <- tempdir()

# Fetch and process elevation data
elev_data <- geodata::elevation_30s(
  country = "CAN", 
  mask = TRUE, 
  path = temp_dir
)

# Fetch temperature data
temp_data <- geodata::worldclim_country(
  country = "CAN", 
  var = "tavg", 
  res = 10, 
  path = temp_dir
)

# Fetch administrative boundaries for Canada
canada_boundaries <- geodata::gadm(
  country = "CAN", 
  level = 1, 
  path = temp_dir
)

# Filter and process British Columbia boundaries
bc_boundaries <- canada_boundaries[canada_boundaries$NAME_1 == "British Columbia", ]
bc_boundaries <- st_as_sf(bc_boundaries)
bc_boundaries <- st_transform(bc_boundaries, crs = st_crs(elev_data))

# Crop and mask data to British Columbia extent
temp_bc <- terra::mask(
  terra::crop(temp_data, terra::ext(bc_boundaries)), 
  bc_boundaries
)

elev_bc <- terra::mask(
  terra::crop(elev_data, terra::ext(bc_boundaries)), 
  bc_boundaries
)

# Verify the processed data
print(terra::ext(temp_bc))
print(terra::ext(elev_bc))
```

## Annual temperature variation of B.C.

```{r,fig.height=8, fig.width=12}
#' Create Temperature Distribution Maps for British Columbia
create_temp_maps <- function(temp_data,
                           main_title = "Temperature Distribution in British Columbia",
                           color_scheme = "RdYlBu",
                           reverse_colors = TRUE,
                           n_colors = 100) {
  
  # Load required packages
  if (!requireNamespace("raster", quietly = TRUE)) {
    install.packages("raster")
  }

  library(raster)
  # Try to convert data to raster if it isn't already
  if (!inherits(temp_data, c("RasterStack", "RasterBrick"))) {
    tryCatch({
      temp_data <- stack(temp_data)
    }, error = function(e) {
      stop("Unable to convert temp_data to RasterStack. Please ensure data is in correct format.")
    })
  }
  
  # Define month names
  month_names <- c("January", "February", "March", 
                  "April", "May", "June",
                  "July", "August", "September", 
                  "October", "November", "December")
  
  # Set up the plotting layout
  original_par <- par(no.readonly = TRUE)
  on.exit(par(original_par))
  
  # Configure layout and margins
  par(mfrow = c(3, 4),
      oma = c(3, 3, 3, 3),
      mar = c(2, 2, 2, 2),
      mgp = c(2, 0.75, 0))
  
  # Create color palette
  col_palette <- hcl.colors(n_colors, color_scheme, rev = reverse_colors)
  
  # Plot each month
  for (i in 1:nlayers(temp_data)) {
    # Extract and plot single layer
    month_data <- temp_data[[i]]
    
    plot(month_data,
         main = month_names[i],
         col = col_palette,
         legend = TRUE,
         axes = TRUE,
         box = TRUE,
         xaxt = "n",
         yaxt = "n")
    
    # Add custom axes
    axis(1, at = seq(-135, -115, by = 5), las = 1, cex.axis = 0.8)
    axis(2, at = seq(50, 58, by = 2), las = 2, cex.axis = 0.8)
  }
  
  # Add titles and captions
  mtext(main_title,
        side = 3,
        outer = TRUE,
        line = 1,
        cex = 1.2,
        font = 2)
  
  mtext("Based on 10-minute resolution WorldClim data",
        side = 3,
        outer = TRUE,
        line = 0,
        cex = 0.8)
  
  mtext("X axis is Latitude and Y axis is Longitude",
        side = 1,
        outer = TRUE,
        line = 1,
        cex = 0.8)
}
create_temp_maps(temp_bc)
```

## Insights Plot 1.1

 - Winter months show cooler temperatures throughout the region, especially evident with blue and green colors.
 - Spring months have few regions with cold temperatures but mostly warmer temperatures spreading across more areas.
 - Summer months exhibit the warmest temperatures across the region. July and August, in particular, show extensive areas experiencing temperatures 15°C and above.

## Insights Plot 1.1
 - In Fall season, temperatures begin to cool.
 - Coastal areas show milder temperatures year-round possibly due to the moderating effect of the ocean.
 - The inland areas, particularly in the north and the central regions, exhibit more extreme variations, with colder winters and warmer summers. This pattern highlights the continental climate influence away from the coast.

## Elevation rast for British columbia

```{r,fig.height=8, fig.width=12}
create_bc_elevation_map <- function(elev_data,
                                  title = "British Columbia Elevation Map") {
  
  # Set up plotting parameters
  original_par <- par(no.readonly = TRUE)
  on.exit(par(original_par))
  
  # Configure margins and layout
  par(mar = c(5, 5, 4, 6))
  
  # Create a custom color palette (different from example)
  my_colors <- colorRampPalette(c("darkblue", "lightblue", 
                                 "yellowgreen", "yellow"))(100)
  
  # Main plot without legend first
  plot(elev_data,
       main = title,
       col = my_colors,
       axes = TRUE,
       box = TRUE,
       xlab = "Longitude (Degrees)",
       ylab = "Latitude (Degrees)",
       legend = FALSE)  # Disable automatic legend
  
  # Add custom legend
  elevation_breaks <- seq(0, 3500, by = 500)
  legend_colors <- my_colors[seq(1, length(my_colors), 
                                length.out = length(elevation_breaks))]
  
  # Add legend manually
  legend(x = "right",
         legend = elevation_breaks,
         fill = legend_colors,
         title = "Elevation (m)",
         bty = "n",     # No box around legend
         xpd = TRUE,    # Allow plotting outside figure region
         inset = c(-0.03, 0))  # Adjust position outside plot
  
  
  # Add simple compass rose (different design)
  arrow_x <- -136
  arrow_y <- 50
  arrow_size <- 1
  
  # Draw simplified compass
  arrows(arrow_x, arrow_y,
         arrow_x, arrow_y + arrow_size,
         length = 0.1, lwd = 2)
  text(arrow_x, arrow_y + arrow_size * 1.3, "N",
       cex = 1, font = 2)
  

}

# Usage example:
create_bc_elevation_map(elev_bc)
```

## Insights Plot 1.2
 - The coastal regions show lower elevations as indicated by the dark blue colors.
 - The interior regions, as in the central parts of the province, display higher elevations, with the highest peaks appearing in shades of yellow.

3.  Visualize wildfires over time between 2012-2017 overtop a temperature raster.

```{r}
## Took help from Claud and Chatgpt to develop this chunk
# Filter wildfire data for the years 2012 to 2017
df_his_wildfire <- df_his_wildfire %>%
  filter(year >= 2012 & year <= 2017)

# Extract the month of discovery and assign a season label
df_his_wildfire <- df_his_wildfire %>%
  mutate(
    disc_month = as.numeric(format(discovery_date, "%m")),
    season_label = case_when(
      disc_month %in% c(9, 10, 11) ~ "Fall",
      disc_month %in% c(3, 4, 5)   ~ "Spring",
      disc_month %in% c(12, 1, 2)  ~ "Winter",
      disc_month %in% c(6, 7, 8)   ~ "Summer"
    )
  )

# Convert the wildfire data into an 'sf' object for spatial operations
wildfire_sf <- st_as_sf(
  df_his_wildfire,
  coords = c("longitude", "latitude"),
  crs = 4326
)

# Function to compute average temperature for a specified season
compute_seasonal_temperature <- function(temperature_data, season_name) {
  season_months <- switch(season_name,
    "Fall"   = c(9, 10, 11),
    "Spring" = c(3, 4, 5),
    "Winter" = c(12, 1, 2),
    "Summer" = c(6, 7, 8)
  )
  # Calculate mean temperature for the selected months
  season_layers <- temperature_data[[season_months]]
  mean(season_layers)
}

# Set up a color palette for temperature visualization
num_colors <- 256
palette_name <- "inferno"
reverse_palette <- FALSE
temperature_palette <- hcl.colors(num_colors, palette_name, rev = reverse_palette)

temp_color_func <- colorNumeric(
  palette = temperature_palette,
  domain = values(temp_bc),
  na.color = "transparent"
)

# Assign distinct colors to each season
season_colors <- list(
  "Winter" = "#00FFFF",  # Aqua
  "Spring" = "#FFD700",  # Gold
  "Summer" = "#FF00FF",  # Magenta
  "Fall"   = "#006400"   # DarkGreen
)

# Initialize the leaflet map with base tiles
leaflet_map <- leaflet() %>%
  addProviderTiles("CartoDB.Positron")

# Get the list of years and seasons to create layers
year_list <- unique(wildfire_sf$year)
season_list <- c("Winter", "Spring", "Summer", "Fall")

# Initialize a vector to store group names for layer control
group_names <- c()

# Loop through each year and season to add layers to the map
for (current_year in year_list) {
  for (current_season in season_list) {
    # Filter the wildfire data for the specific year and season
    seasonal_fires <- wildfire_sf %>%
      filter(year == current_year, season_label == current_season)
    
    # Generate a unique group name for the map layers
    group_name <- paste(current_year, current_season, sep = " ")
    
    if (nrow(seasonal_fires) > 0) {
      group_names <- c(group_names, group_name)
      
      # Compute the seasonal temperature raster
      season_temperature <- compute_seasonal_temperature(temp_bc, current_season)
      season_temp_raster <- raster(season_temperature)
      
      # Add the temperature raster layer to the map
      leaflet_map <- leaflet_map %>%
        addRasterImage(
          season_temp_raster,
          colors = temp_color_func,
          opacity = 0.7,
          group = group_name
        )
      
      # Add wildfire markers for the current season
      leaflet_map <- leaflet_map %>%
        addCircleMarkers(
          data = seasonal_fires,
          color = season_colors[[current_season]],
          radius = ~sqrt(size_ha) / 40,
          fillOpacity = 0.7,
          stroke = TRUE,
          label = ~paste(
            "Year:", year,
            "<br>Season:", season_label,
            "<br>Size (ha):", round(size_ha)
          ),
          group = group_name
        )
    }
  }
}

# Finalize the map with a legend and layer controls
leaflet_map <- leaflet_map %>%
  addLegend(
    position = "topright",
    title = "Seasons",
    colors = unlist(season_colors),
    labels = names(season_colors),
    opacity = 1
  )%>%
  addLegend(
    position = "bottomleft",
    pal = temp_color_func,
    values = values(temp_bc),
    title = "Temperature (°C)",
    opacity = 0.7
  ) %>%
  addLayersControl(
    overlayGroups = group_names,
    options = layersControlOptions(collapsed = TRUE)
  ) %>%
  hideGroup(group_names) %>% 
  setView(
    lng = mean(st_coordinates(wildfire_sf)[, 1], na.rm = TRUE),
    lat = mean(st_coordinates(wildfire_sf)[, 2], na.rm = TRUE),
    zoom = 4
  )

# Display the interactive map
leaflet_map

```
## Insights Plot 2
 - This map displays wildfire incidents by year and season, overlaid on seasonal temperature data. Use the control panel to select different years and seasons.
 - After zooming in, It represent various fire occurences in different years with variation of colors showing different seasons

4.  how do temperature/elevation impact fire occurence?

```{r, echo=FALSE, results='hide'}
## Extracting Temperature values during the month of fireoccurence and Elevation of the place at given location 
# Convert the sf object to a SpatVector
wildfire_vect <- vect(wildfire_sf)

# Extract temperature values at fire locations for all layers
temp_values <- terra::extract(temp_bc, wildfire_vect)

# Ensure 'disc_month' is an integer between 1 and 12
fire_months <- as.integer(wildfire_sf$disc_month)

# Use matrix indexing to select the temperature value for each fire
temp_at_fire <- temp_values[cbind(1:nrow(temp_values), fire_months + 1)]  # '+1' accounts for 'ID' column

# Add the extracted temperatures to the 'wildfire_sf' data frame
wildfire_sf$temp_at_fire <- temp_at_fire

# Extract elevation values at wildfire locations
elev_at_fire <- terra::extract(elev_bc, wildfire_vect)[,2] #1st is ID column so using 2nd column to extract

# Add the elevation values to the 'wildfire_sf' data frame
wildfire_sf$elev_at_fire <- elev_at_fire
```

## Fire occurences of different size at various Temperatures

```{r,fig.height=8, fig.width=12}
ggplot(wildfire_sf, aes(x = temp_at_fire, y = size_ha)) +
  geom_jitter(alpha = 0.4, color = "firebrick", width = 0.2, height = 0) +
  scale_y_log10(
    breaks = c(1, 10, 100, 1000, 10000, 100000),
    labels = scales::comma
  ) +
  labs(
    title = "Analyzing the relationship between temperature and fire size",
    subtitle = "Temperatures at which fires occur range from below 0°C to above 20°C. \n However, most of the data points arecluster between 5°C and 15°C",
    caption = "Data source: BC Wildfire Service",
    x = "Temperature at Fire Location and Month (°C)",
    y = "Fire Size (hectares in log scale)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 13), # Center the title
    plot.subtitle = element_text(hjust = 0.5, size = 9), # Center the subtitle
    plot.caption = element_text(hjust = 1) # Center the caption
  )
```
##Insights Plot 3
- Most fires occur between 5°C and 15°C
- Larger fires occur at a range of temperatures, not only at the higher end. It implies that other factors are also significant drivers of fire size and occurences.

## Fire occurences of different size at various Elevations

```{r,fig.height=8, fig.width=12}
ggplot(wildfire_sf, aes(x = elev_at_fire, y = size_ha)) +
  geom_jitter(alpha = 0.4, color = "darkgreen", width = 0.2, height = 0) +
  scale_y_log10(
    breaks = c(1, 10, 100, 1000, 10000, 100000),
    labels = scales::comma
  ) +
  scale_x_continuous(
    breaks = seq(0, 3000, 500),  # Adding more points by setting breaks every 200 meters
    labels = scales::comma
  ) +
  labs(
    title = "Examining how elevation influences fire size",
    subtitle = "Fires occur at a wide range of elevations, from nearly sea level to over 2000 meters. \n There appears to be a concentration of data points within the 500 to 1500 meters range",
    caption = "Data source: BC Wildfire Service",
    x = "Elevation at Fire Location (meters)",
    y = "Fire Size (hectares in log scale)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 13), # Center the title
    plot.subtitle = element_text(hjust = 0.5, size = 9), # Center the subtitle
    plot.caption = element_text(hjust = 1) # Center the caption
  )
```
## Insights Plot 4
- In the elevation range of 500 to 1500 meters, a significant proportion of the area where fires are both frequent and occasionally very large.
- At higher altitudes and near sea level there are comparibly small number of fire occurrences.

5.  How does the historical distribution (2012-2017) of wildfires differ from this year's (2024) wildfires?

```{r, echo=FALSE, results='hide'}
current_fire_points <- suppressWarnings(st_read("/Users/arpansharma/Desktop/MDS/Data*6200/Assignment/Assignment_2/sharma_arpan_a2/prot_current_fire_points.shp"))%>%
  st_transform(4326)
```

```{r, echo=FALSE, results='hide'}
current_fire_points <- current_fire_points %>%
  rename_all(tolower) %>%
  mutate(across(where(is.character), tolower))
```

```{r, echo=FALSE, results='hide'}
# Adding latitude and longitude as separate columns
wildfire_sf_aligned <- wildfire_sf %>%
  mutate(
    latitude = st_coordinates(.)[, "Y"],
    longitude = st_coordinates(.)[, "X"]
  ) %>%
  dplyr::select(
    year = year,
    fire_num = fire_number,
    geographic = geographic,
    latitude = latitude,
    longitude = longitude,
    size_ha = size_ha,
    geometry = geometry
  )

current_fire_points_aligned <- current_fire_points %>%
  dplyr::select(
    year = fire_year,
    fire_num = fire_num,
    geographic = geographic,
    latitude = latitude,
    longitude = longitude,
    size_ha = current_sz,
    geometry = geometry
  )
```

## Historic Fire Occurences vs Current Fire Occurences

```{r,fig.height=8, fig.width=12}
# Bind the data frames ensuring they are aligned
all_fires <- rbind(wildfire_sf_aligned, current_fire_points_aligned)

# Split data back into historical and current for mapping
historical_fires <- all_fires %>% filter(year < 2024)
current_fires <- all_fires %>% filter(year == 2024)

# Convert SpatRaster to RasterLayer
elev_raster_layer <- raster(elev_bc)
# create pretty breaks for fire sizes
size_values <- pretty(c(sqrt(min(all_fires$size_ha)), sqrt(max(all_fires$size_ha))), n = 5)  

# Create the Leaflet map
map <- leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addRasterImage(elev_raster_layer, colors = colorNumeric(palette = "YlOrRd", values(elev_raster_layer), na.color = "transparent"), opacity = 1, group = "Elevation") %>%
  addCircleMarkers(
    data = historical_fires,
    ~longitude, ~latitude,
    color = "darkblue",
    radius = ~sqrt(size_ha) / 10,
    popup = ~paste("Year:", year, "<br>Size (ha):", size_ha),
    group = "Historical Fires"
  ) %>%
  addCircleMarkers(
    data = current_fires,
    ~longitude, ~latitude,
    color = "darkred",
    radius = ~sqrt(size_ha) / 10,
    popup = ~paste("Year:", year, "<br>Size (ha):", size_ha),
    group = "Current Fires"
  ) %>%
  addLayersControl(
    overlayGroups = c("Historical Fires", "Current Fires"),
    options = layersControlOptions(collapsed = FALSE)
  ) %>%
  addLegend(
    position = "bottomleft",
    title = "Fire Type by Time",
    colors = c("darkblue", "darkred"),
    labels = c("Historical Fires", "Current Fires"),
    opacity = 0.9
  )

# Render the map
htmltools::browsable(map)
```

## Insights Graph 5

 - This Visualization depict the distribution of wildfires in British Columbia, distinguished by historical in blue and current occurrences in red.
 - In historical data, fire occurences convering largers areas impacted central region where as in current occurrences same occured in northern area.
