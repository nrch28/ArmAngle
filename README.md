# Arm Angle Calculation Validation

## Overview 

While building a r shiny trackman app, I initially wanted to enclude arm angle calculations. However, I didn't have access to any kind of motion capture data, so I couldn't directly compute the angles. 
I found an article by Logan Mottley (https://web.archive.org/web/20230123183755/https://www.rundownbaseball.com/project/calculating-arm-angles-using-statcast-data/) that approximates arm angle by estimating the pitcher's shoulder height at release as 0.7 x the pitcher's total height and uses basic trig to compute the angle. Since I had access to all the data to use this method (Trackman + Player Heights), this could possibly allow me to add arm angles into the app. 

To make sure this method was valid, I wanted to compare arm angles using this method to arm angles from baseball savant (since when the article was published, baseball savant didn't publish arm angles). 

## Results

After pulling player heights and merging it with release point and arm angle data, I was left with "arm_angle_data.csv" Here is the plot for the approxamated vs savant arm angles:

![Alt text](ArmAnglePlot.png)

As you can see, there is definitely a relationship between the two, but there are problems with the calculation for more over the top throwers (which Mottley also talked about in his article).

I also took the mean and median of the absolute difference between the savant and calculated values as got 8.367 and 7.132 degrees respectively. 

With taking this into consideration, I concluded that there was too much error associated with this method to include it in the app. 
