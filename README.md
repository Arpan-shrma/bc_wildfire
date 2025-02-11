# British Columbia Wildfire Distribution Analysis (2012-2024)

## Project Overview
This project analyzes the distribution of wildfires in British Columbia over time, comparing historical data (2012-2017) with current (2024) patterns. The analysis includes investigation of climate and environmental factors that influence fire likelihood, with a focus on temperature and elevation impacts.

## Key Features
- Historical wildfire data scraping (2012-2017)
- Temperature and elevation data analysis using geodata package
- Temporal and spatial visualization of wildfire distributions
- Environmental factor impact analysis
- Historical vs current wildfire pattern comparison

## Dependencies
- tidyverse
- dplyr
- readxl
- lubridate
- patchwork
- rvest
- janitor
- ggplot2
- sf
- raster
- sp
- rgdal
- geodata
- gganimate
- terra
- leaflet
- osmdata
- xml2
- shiny

## Installation

```r
# Install required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
    rvest, janitor, dplyr, ggplot2, sf, raster, sp, rgdal, 
    tidyverse, geodata, gganimate, terra, leaflet
)
```

## Data Sources
- Historical wildfire data: BC Government Wildfire Statistics
- Current wildfire data: BC Wildfire Service
- Temperature and elevation data: geodata package

## Key Findings

### Temperature Distribution
- Significant seasonal temperature variations across BC
- Coastal areas show milder year-round temperatures
- Inland regions experience more extreme temperature variations

### Elevation Impact
- Most fires occur between 500-1500 meters elevation
- Fewer fire occurrences at higher altitudes and near sea level
- Complex relationship between elevation and fire size

### Temperature-Fire Relationship
- Most fires occur between 5°C and 15°C
- Fire size shows correlation with temperature
- Other environmental factors also influence fire occurrence

### Historical vs Current Distribution
- Historical fires (2012-2017) concentrated in central regions
- Current fires (2024) show higher occurrence in northern areas
- Pattern shifts suggest changing wildfire dynamics

## Visualizations
The project includes several interactive and static visualizations:
- Monthly temperature distribution maps
- Elevation profile of British Columbia
- Interactive wildfire occurrence maps
- Temperature-fire size relationship plots
- Elevation-fire size relationship plots
- Historical vs current fire distribution comparisons

## Usage
1. Clone the repository
2. Install required dependencies
3. Run the R markdown file
4. Explore interactive visualizations and analysis results

## Contributing
Contributions are welcome! Please feel free to submit pull requests, report bugs, or suggest features.

## License
This project is licensed under the MIT License - see the LICENSE file for details.

## Author
Arpan Sharma

## Acknowledgments
- British Columbia Wildfire Service for data access
- WorldClim for climate data
- geodata package maintainers
