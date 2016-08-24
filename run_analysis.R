

run_analysis <- function(outfile="./tidy_data_set.txt",outwidth="WIDE")
{
      
require(dplyr)
require(tidyr)
require(data.table)       
        
## 0. PRELIMINARY STEPS.

## First check to see that directory structure and zip file are present.
## If not, directory will be created within the working directory and 
## the .zip will be downloaded and extracted.

oldwd <- getwd()

if(!file.exists("./Data/Week4/"))
        {
        dir.create("./Data/Week4/",showWarnings = FALSE,recursive = TRUE)
        }

setwd("./Data/Week4/")  
uci <- "getdata_projectfiles_UCI HAR Dataset.zip"

if(!file.exists("./UCI HAR Dataset/"))
        {
        if(!file.exists(uci))  
                {
                zipurl <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
                download.file(zipurl,uci)
                }
        unzip(uci)
        }

## Now read in activity, features, and subject labels, 
## as well as train/test data.  Use fread() and tbl_df()
## for speed and convenience.

actvdescr <- tbl_df(fread("./UCI HAR Dataset/activity_labels.txt",
                          col.names=c("activity.num","activity")))
trainactv <- tbl_df(fread("./UCI HAR Dataset/train/y_train.txt",
                          col.names=c("activity.num")))
testactv  <- tbl_df(fread("./UCI HAR Dataset/test/y_test.txt",
                          col.names=c("activity.num")))
trainsubj <- tbl_df(fread("./UCI HAR Dataset/train/subject_train.txt",
                          col.names=c("subject")))
testsubj  <- tbl_df(fread("./UCI HAR Dataset/test/subject_test.txt",
                          col.names=c("subject")))
features  <- tbl_df(fread("./UCI HAR Dataset/features.txt",sep=" ",
                          col.names=c("feature.num","feature")))
traindata <- tbl_df(fread("./UCI HAR Dataset/train/X_train.txt"))
testdata  <- tbl_df(fread("./UCI HAR Dataset/test/X_test.txt"))



## Now that the data is loaded check to verify that a WIDE or NARROW output 
## has been selected.  CASE must match

if(!(outwidth=="NARROW" | outwidth=="WIDE"))
        {getwidth <- function() 
                {
                w<-readline(prompt="Choose a NARROW or WIDE output:")
                if(!(w=="NARROW" | w=="WIDE")) {w <-getwidth()}
                return(w)
                }
        outwidth <- getwidth()
        }

## 1. MERGE TRAINING AND TEST SETS.

## Data first
masterdata <- bind_rows(traindata, testdata)

##verify order is maintained
if(any(head(masterdata) != head(traindata)) | 
   any(tail(masterdata) != tail(testdata)))
        {warning("Order of datasets has not been preserved.")}

## Now merge Subjects
mastersubjects <- bind_rows(trainsubj,testsubj)

## Finally merge Activities
masteractivities <- bind_rows(trainactv,testactv)

## 2. EXTRACT MEASUREMENTS ON MEAN & STANDARD DEVIATIONS.

## First identify relative position of each feature name with -mean() or -std().
## Per the README.txt these are the only mean and standard deviation fields.

mean.std.features <- filter(features,grepl("-mean\\(\\)|-std\\(\\)",feature))

## Now extract only those columns which contain -mean() or -std().

meanstd.data <- select(masterdata,mean.std.features$feature.num)

## 3. USE DESCRIPTIVE ACTIVITY NAMES TO NAME ACTIVITIES IN DATA SET.

## First combine Subjects, Activities, and Data.
masterset <- bind_cols(mastersubjects,masteractivities,meanstd.data)

## Now use inner_join() to bring in activity descriptions & remove activity.num.

masterset <- inner_join(actvdescr,masterset,by="activity.num")
masterset <- select(masterset,-activity.num)

## 4. APPROPRIATELY LABEL DATA SET WITH DESCRIPTIVE VARIABLE NAMES
##
## Note that per discussion in multiple locations referenced in the run_analysis 
## ReadMe, that multiple formats of the final data set are acceptable.  THis 
## function allows for the creation of either a WIDE or NARROW data set.
## Either one of these may be tidy--depending upon the intended application.
## Given disagreement about which is more applicable this script allows for the
## of either type.

## First expand the Features set to include more exacting descriptors.
## These have been identified via review of the source readme file.

mean.std.features$calculation[grepl("-mean\\(\\)",
                                   mean.std.features$feature)] <- "mean"
mean.std.features$calculation[grepl("-std\\(\\)",
                                   mean.std.features$feature)] <- "standard_deviation"

mean.std.features$source[grepl("^.Body",mean.std.features$feature)] <-  "body"
mean.std.features$source[grepl("^.Gravity",
                               mean.std.features$feature)] <-  "gravity"

mean.std.features$signal <- "acceleration"
mean.std.features$signal[grepl("Jerk",mean.std.features$feature)] <-  "jerk"
mean.std.features$signal[grepl("JerkMag",
                               mean.std.features$feature)] <-  "jerk_magnitude"
mean.std.features$signal[grepl("Mag",mean.std.features$feature) & 
                        !grepl("Jerk",mean.std.features$feature)] <-  "acceleration_magnitude"

mean.std.features$domain[grepl("^t",mean.std.features$feature)] <-  "time"
mean.std.features$domain[grepl("^f",mean.std.features$feature)] <-  "frequency"

mean.std.features$direction <- "no_direction"
mean.std.features$direction[grepl("-[Xx]$",
                                  mean.std.features$feature)] <- "x_axis"
mean.std.features$direction[grepl("-[Yy]$",
                                  mean.std.features$feature)] <- "y_axis"
mean.std.features$direction[grepl("-[Zz]$",
                                  mean.std.features$feature)] <- "z_axis"

mean.std.features$sensor[grepl("Acc",
                               mean.std.features$feature)] <-  "accelerometer"
mean.std.features$sensor[grepl("Gyro",
                               mean.std.features$feature)] <-  "gyroscope"

## Now either apply these to names(masterset) if WIDE, or as extra fields if
## NARROW.

if(outwidth=="NARROW") 
{
        names(masterset)[3:68] <- mean.std.features$feature
        outset <- masterset %>%
                        gather(key=feature,measure,-subject,-activity) %>%
                        inner_join(mean.std.features,by="feature") %>%
                        select(-feature,-feature.num)  
        outset[,3:9]<-outset[,c(4:9,3)]
        names(outset)[3:9]<-names(outset)[c(4:9,3)]
}
if(outwidth=="WIDE")
{
        outset.names <-     
                mean.std.features %>%
                        group_by(feature.num) %>%
                        summarize(description=paste(calculation,
                                                    source,
                                                    signal,
                                                    domain,
                                                    direction,
                                                    sensor,
                                                    sep=".")) %>%
                        ungroup() %>%
                        select(description)
        names(masterset)[3:68]<-outset.names$description
}

## 5. FROM THE DATA SET IN STEP 4, CREATE A SECOND, INDEPEDENT TIDY SET 
## WITH THE AVERAGE OF EACH VARIABLE FOR EACH ACTIVITY AND EACH SUBJECT.
if(outwidth=="NARROW") 
        { outset <- masterset %>% 
                        group_by(subject,
                                  activity,
                                  calculation,
                                  source,
                                  signal,
                                  domain,
                                  direction,
                                  sensor) %>%
                        summarize_each(funs(mean))
        }
else    {outset <- masterset %>% 
                        group_by(subject,
                                  activity) %>%
                        summarize_each(funs(mean))} 

write.table(outset,file=outfile,row.names=FALSE)

setwd(oldwd) 

}

run_analysis()
