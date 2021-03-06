# setwd('H:/Machine_Learning/DTA')
setwd('/Users/ivan/Work_directory/DTA')
rm(list=ls());gc()
require(glmnet);require(data.table)

# main_df <- data.frame(fread('data/main_df_182features.csv',header = T, stringsAsFactor = F))
# load(file='data/main_df_138features.RData')
head(main_df)
datadirectory <- 'data/drivers/'
drivers <- sort(as.numeric(list.files(datadirectory)))

##################
### Classifier ###
##################
classifier <- function(driver, model='gbm', nrOfDriversToCompare=5, features) {
    currentData <- main_df[main_df[,1]==driver,]
    #currentData$target <- 1
    test_num <- sample(drivers[which(drivers!=driver)],nrOfDriversToCompare)
    refData <-  main_df[main_df[,1] %in% test_num,]
    refData$target <- 'No'
    train <- rbind(currentData, refData)
    
    #model
    preProcValues <- preProcess(train[,c(features)], method = c("center", "scale", "pca"))
    train[,c(features)] <- predict(preProcValues, train[,c(features)])
    currentData[,c(features)] <- predict(preProcValues, currentData[,c(features)])
    
    g <- glmnet(x = data.matrix(train[,-c(1,2,ncol(train))]), y = data.matrix(train$target),family = "binomial", alpha = 0.99, 
                standardize = F, intercept = T, type.logistic = "Newton")
    p <- predict(g, newx = data.matrix(currentData[,-c(1,2,ncol(currentData))]), type = "response")
    
    result <- data.frame(driver_trip=paste0(currentData[,1],'_',currentData[,2],sep=''), prob=p[,dim(p)[2]])
    return(result)
}

#################
### Main Loop ###
#################
# library(doMC)
# registerDoMC(cores = 2)
# load('Driver-Telematics-Analysis/feature_selection/rfe_var_190.RData')
set.seed(6886)

feature_list <- colnames(main_df[,-c(1,2,ncol(main_df))])
submission <- data.frame()

for (driver in drivers){
    result <- classifier(driver,'glmnet',5,feature_list)
    print(paste0('driver: ', driver, ' | ' ,date())) 
    
    submission <- rbind(submission, result)
}

write.csv(submission, file = 'submission_glmnet_172_099_PCA_semi.csv', quote = F, row.names = F)
sum(is.na(submission))
