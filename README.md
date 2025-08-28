# Arm Angle Calculation Validation

## Overview 

While building a r shiny trackman app, I initially wanted to enclude arm angle calculations. However, I didn't have access to any kind of motion capture data, so I couldn't directly compute the angles. 
I found an article by Logan Mottley (https://web.archive.org/web/20230123183755/https://www.rundownbaseball.com/project/calculating-arm-angles-using-statcast-data/) that approximates arm angle by estimating the pitcher's shoulder height at release as 0.7 x the pitcher's total height and uses basic trig to compute the angle. Since I had access to all the data (Trackman + Player Heights) to use this method, this could possibly allow me to add arm angles into the app. 

To make sure this method was valid, I wanted to compare arm angles using this method to arm angles from baseball savant (since when the article was published, baseball savant didn't publish arm angles). 

## Results

After pulling player heights and merging it with release point and arm angle data, I was left with "arm_angle_data.csv" Here is the plot for the approxamated vs savant arm angles:


As you can see, 
