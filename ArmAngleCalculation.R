library(tidyverse)
library(baseballr)

# Custom NULL-coalescing operator
`%||%` <- function(x, y) if (!is.null(x) && !all(is.na(x))) x else y

# Function to get all pitchers with names and IDs
get_season_pitchers <- function(year) {
  tryCatch({
    teams <- mlb_teams(year) %>% 
      filter(sport_name == "Major League Baseball") %>%
      pull(team_id)
    
    map_dfr(teams, ~{
      tryCatch({
        roster <- mlb_rosters(team_id = .x, season = year, roster_type = "active")
        
        # Create base table with IDs and names
        roster %>%
          filter(position_abbreviation == "P") %>%
          transmute(
            player_id = as.character(person_id %||% id),
            player_name = person_full_name %||% person.display.full_name %||% player_name,
            team_id = .x
          ) %>%
          distinct(player_id, .keep_all = TRUE)
      }, error = function(e) {
        message("Team ", .x, " processing error: ", e$message)
        NULL
      })
    })
  }, error = function(e) {
    message("Season processing error: ", e$message)
    tibble(player_id = character(), player_name = character(), team_id = character())
  })
}

# Function to get height for a single player
get_player_height <- function(player_id) {
  tryCatch({
    player_info <- mlb_people(person_id = player_id)
    player_info$height %||% NA_character_
  }, error = function(e) {
    message("Error getting height for ", player_id, ": ", e$message)
    NA_character_
  })
}

# Main function to get complete pitcher data
get_complete_pitcher_data <- function(year) {
  # Get all teams
  teams <- mlb_teams(year) %>% 
    filter(sport_name == "Major League Baseball") %>%
    pull(team_id)
  
  # Get all pitchers with names and IDs
  pitchers <- map_dfr(teams, ~{
    roster <- mlb_rosters(team_id = .x, season = year, roster_type = "active")
    roster %>%
      filter(position_abbreviation == "P") %>%
      transmute(
        player_id = as.character(person_id),
        player_name = person_full_name,
        team_id = .x
      ) %>%
      distinct(player_id, .keep_all = TRUE)
  })
  
  # Add heights in one go
  pitchers %>%
    mutate(
      height = map_chr(player_id, ~mlb_people(person_id = .x)$height %||% NA_character_),
      height_in = map_dbl(height, ~{
        if (is.na(.x)) return(NA_real_)
        parts <- strsplit(.x, "'|-|\"")[[1]]
        if (length(parts) < 2) return(NA_real_)
        as.numeric(parts[1]) * 12 + as.numeric(parts[2])
      })
    ) %>%
    filter(!is.na(height_in)) %>%  # Remove pitchers without height data
    select(player_id, player_name, team_id, height, height_in)
}

# Convert height to inches
height_to_inches <- function(height_str) {
  parts <- strsplit(height_str, "'|-|\"")[[1]]
  feet <- as.numeric(parts[1])
  inches <- as.numeric(parts[2])
  return(feet * 12 + inches)
}

# --------------------------

pitchers_2024 <- get_complete_pitcher_data(2024)

# ---------------------------------------------- process savant data

# API wasn't working for savant, so just downloaded 2024 data 
raw_savant_data <- read.csv("C:/Users/nrch0/Downloads/RDPitching/Arm Angle Valid/savant_data.csv")

savant_data <- raw_savant_data %>% select("player_id", "player_name", "release_extension", "release_pos_x", "release_pos_z", "arm_angle")

merged_data <- merge(savant_data, pitchers_2024, by = "player_id" )

# ------------ Calculate Arm Angle using height, release point------------------


# Function to calculate height-adjusted arm angle
calculate_arm_angle <- function(release_pos_x, release_pos_z, extension, height_in) {
  # Convert to inches (Statcast uses feet)
  x_in <- release_pos_x * 12
  z_in <- release_pos_z * 12
  extension_in <- extension * 12
  
  # Shoulder height (70% of total height)
  shoulder_height <- 0.7 * height_in
  
  x_abs <- abs(x_in)
  
  # Adjusted release height relative to shoulder
  adjusted_z <- z_in - shoulder_height
  
  # Calculate angle (degrees)
  atan2(adjusted_z, x_abs) * (180 / pi)
}

# ------ combine data so we can compare calculated vs savant arm angles -------- 

full_data <- merged_data %>% mutate(arm_angle_calculated = calculate_arm_angle(release_pos_x = release_pos_x, release_pos_z = release_pos_z, extension = release_extension, height_in = height_in))

arm_angle_data <- full_data %>% select(player_id, player_name.x, arm_angle, arm_angle_calculated)
arm_angle_data <- arm_angle_data %>% rename(player_name = player_name.x)

# save arm angle data (calculated and savant) 
write.csv(arm_angle_data, "arm_angle_data.csv")

# ------------------------------ test -----------------------------------------

full_data <- read.csv("arm_angle_data.csv")

plot(full_data$arm_angle_savant, full_data$arm_angle_calculated_approximation,
     xlab = "Savant",
     ylab = "Calculated",
     main = "Savant Arm Angle vs Calculated Arm Angle")
abline(0,1, col = "red")

full_data$diff <- full_data$arm_angle_calculated_approximation - full_data$arm_angle_savant

# took absolute value because calculation misses in both directions 
full_data$absdiff <- abs(full_data$diff)

mean(full_data$absdiff, na.rm = TRUE) # 8.319 degrees
median(full_data$absdiff, na.rm = TRUE) # 7.223 degrees 
