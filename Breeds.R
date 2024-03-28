##This data set contains information about 277 breeds from github.io/akcdata.
##Also, to add to the data, the breeds and their popularity ranking variables were extracted from American Kennel website using Beautiful Soup.
##This was done in Jupyter Notebook.

##############
##DISCLAIMER
##############
#Every year, the AKC publishes its list of breed rankings by popularity, based on registration statistics. Popularity is based on registration, not 
#on which breed is the most entertaining, smartest, or best-looking. 
##############

##let's do some cleaning in excel
##feature engineer new columns (avg_height, avg_weight, avg_lifespan)

##Load necessary libraries
library(readr)
library(ggplot2)
library(GGally)
library("corrplot")
library(rpart)
library(rpart.plot)
library(cluster)
library(ggrepel)

##set the working directory
getwd()
setwd("C:/Users/satba/OneDrive/Desktop/MS/Coursera/Capstone_8")

##read the data
data<-read_csv("breeds.csv")
head(data)
colnames(data)
dim(data) ##277 X 24

################################################################################
## 1) DATA CLEANING
################################################################################

##subset the data-set to include only the necessary variables
#?subset()
new_data<-subset(data,select=-c(description,popularity_2018,min_height,max_height,min_weight,max_weight,min_expectancy,max_expectancy))
head(new_data)
dim(new_data) #277 X 16
colnames(new_data)
str(new_data)
summary(new_data)

##convert chr() variables to factor()
new_data$Breed <- as.factor(new_data$Breed)
new_data$temperament <- as.factor(new_data$temperament)
new_data$group<-as.factor(new_data$group)
new_data$grooming_frequency_category<-as.factor(new_data$grooming_frequency_category)
new_data$shedding_category<-as.factor(new_data$shedding_category)
new_data$energy_level_category<-as.factor(new_data$energy_level_value)
new_data$trainability_category<-as.factor(new_data$trainability_category)
new_data$demeanor_category<-as.factor(new_data$demeanor_category)
new_data$`avg_height(cm)` <- as.numeric(new_data$`avg_height(cm)`)
new_data$`avg_weight(kg)`<-as.numeric(new_data$`avg_weight(kg)`)
new_data$`avg_lifespan(years)` <- as.numeric(new_data$`avg_lifespan(years)`)

str(new_data)
summary(new_data)

##look for missing values
anyNA(new_data) ##TRUE

new_data <- na.omit(new_data)
dim(new_data) ##235 X 16

##To make the data more interesting let's scrap popularity ranking of dog breeds for years (2018-2022) using Beautiful soup and clean and read them here.
popularity_2018<-read_csv("popularity_2018.csv")
popularity_2019<-read_csv("popularity_2019.csv")
popularity_2020<-read_csv("popularity_2020.csv")
popularity_2021<-read_csv("popularity_2021.csv")
popularity_2022<-read_csv("popularity_2022.csv")

##Merged popularity ranking data for different years with the main data-set by matching the breed names in all csv files. This was done in excel.
new_data <- merge(new_data, popularity_2018, by = "Breed", all.x = TRUE)

new_data <- merge(new_data, popularity_2019, by = "Breed", all.x = TRUE)

new_data <- merge(new_data, popularity_2020, by = "Breed", all.x = TRUE)

new_data <- merge(new_data, popularity_2021, by = "Breed", all.x = TRUE)

new_data <- merge(new_data, popularity_2022, by = "Breed", all.x = TRUE)

##Finding the intersection of breed names between multiple data frames
intersection <- Reduce(intersect, list(new_data$Breed, popularity_2018$Breed, popularity_2019$Breed, popularity_2020$Breed, popularity_2021$Breed, popularity_2022$Breed))
intersection

##of the 235 breeds only 178 have data for the popularity ranking columns.

##############
##DISCLAIMER
##############
##The missing values represent breeds that are not ranked due to lack of registration data.
##############

new_data<-na.omit(new_data)

################################################################################
## 2) DATA EXPLORATION & FEATURE ENGINEERING
################################################################################

##Explore the distribution of height and weight variables using histograms and decide on the cut-off points for creating a new column.
x11()
hist(new_data$`avg_height(cm)`, main = "Average Height Distribution", xlab = "Average Height (cm)")
x11()
hist(new_data$`avg_weight(kg)`, main = "Average Weight Distribution", xlab = "Average Weight (kg)")


##Feature engineering column 'Size'
##let's create a size column and categorize dog breeds into small, medium and large sized ones.
new_data$Size <- NA  ##Create a new column for size category and initialize with NA values

##Define cutoff points for height and weight categories
height_cutoffs <- c(0, 31, 61, 81)
weight_cutoffs <- c(0, 10, 35, 82)

##Categorize size based on average height and weight
new_data$Size[new_data$`avg_height(cm)` <= height_cutoffs[2] & new_data$`avg_weight(kg)` <= weight_cutoffs[2]] <- "Small"
new_data$Size[new_data$`avg_height(cm)` > height_cutoffs[3] & new_data$`avg_weight(kg)` > weight_cutoffs[3]] <- "Large"

##For cases that don't fit into Small or Large categories, assign Medium
new_data$Size[is.na(new_data$Size)] <- "Medium"

##Print the first few rows to verify the new column
head(new_data$Size)

##Calculate the sum of occurrences of the categories
sum(new_data$Size == "Small")
sum(new_data$Size == "Medium")
sum(new_data$Size == "Large")

new_data$Size <- as.factor(new_data$Size)

##Feature engineering column 'score'
##let's create a score column with data score for each dog breed by assigning weights to variables based on personal knowledge.
weight_longevity <- 0.8
weight_temperament <- 0.8
weight_activity <- 0.6
weight_trainability <- 0.6
weight_grooming <- 0.4
weight_shedding <- 0.4

##Calculate score
new_data$score <- with(new_data, (new_data$'avg_lifespan(years)' * weight_longevity) + 
                         (demeanor_value * weight_temperament) + 
                         (energy_level_value * weight_activity) + 
                         (trainability_value * weight_trainability) - 
                         (grooming_frequency_value * weight_grooming) - 
                         (shedding_value * weight_shedding))

##Print first few rows to verify
head(new_data$score)
summary(new_data$score)

##Write the merged data-set to a CSV file
write.csv(new_data, file = "new_data.csv", row.names = FALSE)
dim(new_data) ##178 X 23

##Look for outliers 
##A Z-score, also known as a standard score, is a method to look for outliers and is a measure of how many standard deviations a data point is 
##from the mean of the data-set. It indicates how far a particular observation is from the mean in terms of standard deviation units.

z_scores <- scale(new_data$`avg_weight(kg)`)
outlier_indices <- which(abs(z_scores) > 3) ## 40,142,207,220
##plot the outliers
x11()
plot(new_data$`avg_weight(kg)`, main = "Outliers Detection (weight)", pch = 19, col = ifelse(abs(z_scores) > 3, "red", "blue"))
legend("topleft", legend = c("Normal", "Outlier"), col = c("blue", "red"), pch = 19)
text(x = outlier_indices, y = new_data$`avg_weight(kg)`[outlier_indices], labels = new_data$Breed[outlier_indices], pos = 4, col = "red", srt = -90)


z_scores1 <- scale(new_data$score)
outlier_indices <- which(abs(z_scores1) > 3)
x11()
plot(new_data$score, main = "Outliers Detection (score)", pch = 19, col = ifelse(abs(z_scores1) > 3, "red", "blue"))
legend("topleft", legend = c("Normal", "Outlier"), col = c("blue", "red"), pch = 19)
text(x = outlier_indices, y = new_data$score[outlier_indices], labels = new_data$Breed[outlier_indices], pos = 4, col = "red", srt = 90)

## Not removing the outliers.

################################################################################
## 3) FURTHER EXPLORATION
################################################################################

##Looking for dog breeds with a particular demeanor category.
##Create a data frame
df <- data.frame(new_data$Breed, new_data$demeanor_value, new_data$demeanor_category)

##Rename columns for better readability
colnames(df) <- c("Breed", "Demeanor Value", "Demeanor Category")

##Filter the data frame for breeds categorized as "Aloof/Wary"
aloof_breeds <- subset(df, new_data$demeanor_category == "Aloof/Wary")

##Plot the breeds categorized as "Aloof/Wary"
x11()
barplot(aloof_breeds$`Demeanor Value`, names.arg = aloof_breeds$Breed, 
        main = "Breeds Categorized as 'Aloof/Wary'", xlab = "Breeds", ylab = "Demeanor Value")

##Similarly, we can look for categories within other variables also.

##Scatter-plot matrix to view the relationship between continuous variables.
x11()
pairs(new_data[, c("Rank_2018", "avg_lifespan(years)", "avg_weight(kg)", "score", "Size")],
      col = ifelse(new_data$Size == "Small", "blue", ifelse(new_data$Size == "Medium", "black", "red")), 
      pch = ifelse(new_data$Size == "Small", 16, ifelse(new_data$Size == "Medium", 17, 18)),
      main = "Scatterplot Matrix of Key Variables",
      labels = c("Rank 2018", "Avg Lifespan (years)", "Avg Weight (kg)", "Score","Size"), 
      cex.axis = 1.2, cex.lab = 1.2, 
      cex = 1.5) 

##If the points on the plot form a clear linear pattern, it indicates a strong correlation between the variables.
##For example Avg_weight(years) and Avg_Lifespan(Years).

##Bar plots can be used to explore categorical variables
x11()
par(mar = c(12, 5, 5, 5))
barplot(table(new_data$group), main = "Group Distribution", las = 2)

##Line plot for popularity rankings (years 2018 and 2022)
x11()
plot(new_data$Rank_2018, type = "l", col = "red", ylim = c(1,200), xlab = "Breed", ylab = "Popularity Rank", main = "Popularity Rankings 2018-2022")
lines(new_data$Rank_2022, col = "purple")

##We can see that the lines deviate from each other at some points but intersect mostly.

################################################################################
## 4) CLUSTERING
################################################################################

##Select relevant features for clustering
features <- c("score", "Rank_2022")

##Prepare data by selecting features
clustering_data <- new_data[, features]

##Scale the features to ensure they have equal importance
scaled_data <- scale(clustering_data)

set.seed(123)
##Determine the number of clusters (k = 4 for hotdogs, overlooked treasures, overrated, and rightly ignored)
k <- 4

##Perform k-means clustering
kmeans_result <- kmeans(scaled_data, centers = k)

##Assign cluster labels to each breed
cluster_labels <- kmeans_result$cluster

##Add cluster labels back to the original dataset
new_data$cluster <- cluster_labels

##Display the count of breeds in each cluster
table(new_data$cluster)

##Assign custom labels to the clusters based on their characteristics
cluster_names <- c("Overrated", "Overlooked Treasures", "Hot Dogs","Rightly Ignored")

##Define colors for the clusters
cluster_colors <- c("blue", "green", "red", "purple")

##Rename cluster labels in the dataset
new_data$cluster_label <- cluster_names[new_data$cluster]

##Create a ggplot object
x11()
ggplot(new_data, aes(x = score, y = Rank_2022, color = factor(cluster))) +
  geom_point(size = 3) +  
  labs(title = "K-means Clustering of Dog Breeds", x = "Score", y = "Popularity Rank 2022") +  
  scale_color_manual(values = cluster_colors, labels = cluster_names) +  
  geom_text_repel(aes(label = Breed), box.padding = 0.5, point.padding = 0.1, segment.color = "transparent", size = 2,max.overlaps = 10) +  
  theme(legend.position = "bottom")  
