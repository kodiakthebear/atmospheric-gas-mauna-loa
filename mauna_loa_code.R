library(naniar)
library(reshape2)
# install.packages("beeswarm")
library(beeswarm)
# install.packages("mice")
library(mice)
library(VIM)
library(plotly)
library(ggplot2)
library(corrplot)
library(GGally)
# install.packages("ggcorrplot")
library(ggcorrplot)
library(beeswarm)
library(tidyr)
library(factoextra)
# install.packages("NbClust")
library(NbClust)
library(cluster)
install.packages("mclust")
library(mclust)


MLoa <- read.csv("/Users/mukundranjan/Documents/Academics/Epiphany/DEVUL/Assignments/Assignment 2/MaunaLoa_miss.csv")

# TASK 1 - EDA:


head(MLoa)
str(MLoa)
summary(MLoa)

#Before proceeding, I wish to convert 'Date' to a proper numeric date value for time series plots. 
str(MLoa$Date)
head(MLoa$Date)
MLoa$Date <- as.Date(MLoa$Date, format="%Y-%m-%d")
str(MLoa)    #Ensuring the switch has taken place 
sapply(MLoa, class)

#Proceeding with EDA and relevant visualisations:
colSums(is.na(MLoa))
rowSums(is.na(MLoa))
par(mfrow=c(1,2))
boxplot(MLoa$CO, main="Boxplot of CO", col = "red")                 #Visualising outliers
boxplot(MLoa$CO2, main="Boxplot of CO2", col = "gray")
boxplot(MLoa$Methane, main="Boxplot of Methane", col = "green2")
boxplot(MLoa$NitrousOx, main="Boxplot of NOx", col = "dodgerblue")
boxplot(MLoa$CFC11, main="Boxplot of CFC11s", col = "yellow")
par(mfrow=c(1,1))

ggpairs(MLoa[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")], 
        title = "Scatterplot Matrix of the Mauna Loa Dataset", 
        lower = list(continuous = wrap("points", alpha = 0.6, color = "tomato")),
        upper = list(continuous = wrap("cor", size = 4)))                        #Scatterplot matrix


MLCor <- cor(MLoa[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")], 
             use = "pairwise.complete.obs")       #Correlation and Correlation Plot
ggcorrplot(MLCor, lab=TRUE,lab_size = 5, , colors = c("dodgerblue", "navajowhite", "tomato2" ), 
           ggtheme = theme_classic())

beeswarm(MLoa[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")], 
         horizontal = TRUE, col = "dodgerblue", pch = 16, alpha=0.6)


MLoa_long <- melt(MLoa, id.vars = "Date", variable.name = "Gas", value.name = "Concentration")

ggplot(MLoa_long, aes(x = Date, y = Concentration, color = Gas)) + geom_line() +
  labs(title = "Atmospheric Gas Concentrations at Mauna Loa",
       x = "Date",
       y = "Concentration") + theme_minimal() + facet_wrap(~Gas, scales = "free_y") + theme(legend.position = "bottom")




selected_vars <- c(selected_vars <- c("CO", "CO2", "Methane", "NitrousOx", "CFC11"))
par(mfrow = c(3, 2))  

for (var in selected_vars) {
  hist(MLoa[[var]], main = paste("Histogram of", var), xlab = var, col = "tomato", border = "black")
}


vis_miss(MLoa)        #Visualising missing values

md.pairs(MLoa[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")])

aggr(MLoa[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")], col=mdc(3:4), numbers=TRUE, sortVars=TRUE, labels=names(MLoa),
     cex.axis=.7, gap=3, ylab=c("Proportion of missingness","Missingness Pattern"))

par(mfrow = c(1,1))
marginplot(MLoa[, c("CO", "CO2")], col = mdc(1:2), 
           cex.numbers = 1.2, pch = 19)               #Visualising the missingness for CO and CO2


#Having observed missing values in the dataset, MICE is used to impute values:
imp_MLoa <- mice(MLoa, seed = 123, method = "norm.predict")
MLoa_nomiss <- complete(imp_MLoa)
head(MLoa_nomiss)
str(MLoa_nomiss)

md.pairs(MLoa_nomiss[c("CO","CO2", "Methane", "NitrousOx", "CFC11")])                 #Verifying that missing vals have been removed
aggr(MLoa_nomiss[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")], col=mdc(3:4), numbers=TRUE, sortVars=TRUE, labels=names(MLoa),
     cex.axis=.7, gap=3, ylab=c("Proportion of Missingness","Missingness Pattern"))
vis_miss(MLoa_nomiss)

ggpairs(MLoa_nomiss[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")], 
        title = "Scatterplot Matrix of the Mauna Loa Dataset", 
        lower = list(continuous = wrap("points", alpha = 0.6, color = "tomato")),
        upper = list(continuous = wrap("cor", size = 4)))                        #Scatterplot matrix



# TASK 2 - PCA:

MLoa_scaled <- scale(MLoa_nomiss[c("CO", "CO2", "Methane", "NitrousOx", "CFC11")])    #Scaling to ensure distribution remians unchanged for PCA

#Running PCA
MLoa_pca <- prcomp(MLoa_scaled, center = TRUE, scale. = TRUE)           
summary(MLoa_pca)

#Scree plot and Variable Plot to visualize variance explained
fviz_screeplot(MLoa_pca, addlabels=TRUE)
fviz_pca_var(MLoa_pca, axes = c(1, 2), repel = TRUE,
             col.var = "red")



fviz_contrib(MLoa_pca, choice = "var", axes = 1, top = 10)     #Visualising contributions of varianbles to PC1 and PC2
fviz_contrib(MLoa_pca, choice = "var", axes = 2, top = 10)     #...PC2

MLoa_pca_comp <- as.data.frame(MLoa_pca$x[, 1:2])        #Extracting components




# TASK 3 - Clustering

#Using the cluster scree plot to compute the required clusters for K-means clustering:
fviz_nbclust(MLoa_pca_comp, kmeans, method = "wss")
fviz_nbclust(MLoa_pca_comp, kmeans, method = "silhouette")

#As the WSS and Silhouette methods suggest different Ks for clustering, we will test both approaches:
set.seed(123)

k2 <- kmeans(MLoa_pca_comp, centers = 2, nstart = 25)
k4 <- kmeans(MLoa_pca_comp, centers = 4, nstart = 25)

fviz_cluster(k2, data = MLoa_scaled, ellipse.type = "norm")       #Clustering for both values of k are compared
                                                                  #And k=4 is chosen as it has the highest granularity and
                                                                  #most easily interpreted graph. 
fviz_cluster(k4, data = MLoa_scaled, ellipse.type = "norm")




#K-medoids:
fviz_nbclust(MLoa_scaled, clara, method = "silhouette") + labs(title = "K-Medoids: Optimal No. of Clusters")
MLoa_kmed <- clara(MLoa_scaled, k=9)
fviz_cluster(MLoa_kmed, data = MLoa_scaled, ellipse.type = "norm") + labs(title = "K-Medoids Clustering")


#Gaussian Mixture Model (GMM):
MLoa_mclust <- Mclust(MLoa_scaled, G = 1:10)
plot(MLoa_mclust, what = "BIC")

#Choosing the EVI model and making relevant plots:
MLoa_mc_EVI <- Mclust(MLoa_scaled, G = 6, modelNames = "EVI")
plot(MLoa_mc_EVI, what = "classification")
plot(MLoa_mc_EVI, what = "uncertainty")
plot(MLoa_mc_EVI, what = "density")
plot(MLoa_mc_EVI, what = "BIC")
