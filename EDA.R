setwd("C:/Users/satba/OneDrive/Desktop/SDM/sdm1/assignment")
library(ggplot2)
library(ISLR2)
data(Hitters)
head(Hitters)
#2. Consider the “Hitters” dataset in the ISLR2 package. Suppose that you are 
#getting this data ready to build a predictive model for salary. 
#Pre-process/clean the data, investigate the data using exploratory data analysis 
#such as scatterplots, and other tools we have discussed. Describe your process 
#and justify any changes you have made to the dataset. Submit the cleaned 
#dataset as an *.RData file to BrightSpace. 

#To get some domain knowledge, i studied about these variables and found the below ones much influencing the Salary variable.
#Hits: The number of hits a player achieves in a season can be a good indicator of their offensive performance, which can impact their salary.

#HmRun (Home Runs): Home runs are a key offensive statistic, and players who hit more home runs are often more highly valued and better compensated.

#Runs and RBI (Runs Batted In): Runs scored and runs batted in are also offensive statistics that can influence a player's value and salary.

summary(Hitters) 
sum(is.na(Hitters))  #i see NA's in 59 observations of Salary column

# Handle missing values
#I choose to remove observations with missing values using na.omit(Hitters). This is a reasonable choice, as imputing the 
#missing salaries could introduce bias.
Hitters_omit <- na.omit(Hitters)
dim(Hitters_omit)

#Investigating the data through visualization,I  found this to be a crucial step in understanding potential associations.
# Example scatter plot 
ggplot(Hitters_omit, aes(x = Hits, y = Salary)) +
  geom_point()

ggplot(Hitters_omit, aes(x = Runs, y = Salary)) +
  geom_point()

ggplot(Hitters_omit, aes(x = HmRun, y = Salary)) +
  geom_point()


#convert the categorical variables League, Division and NewLeague to suitable format of binary vectors
Hitters_omit$League <- as.numeric(Hitters_omit$League) - 1
Hitters_omit$Division <- as.numeric(Hitters_omit$Division) - 1
Hitters_omit$NewLeague <- as.numeric(Hitters_omit$NewLeague) - 1

# Save the cleaned dataset as an RData file
save(Hitters_omit, file = "cleaned_Hitters.RData")









