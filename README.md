# GettingandCleaningData
## Overview of References and Design Choices

As with many real world problems, this assignment was subject to much in the way of interpretation.  In-class examples often demonstrated the 'gather'ing of columns such as "male" or "female" which would suggest that a similar decomposition of the raw data file columns into new columns would produce a proper tidy data set which was NARROW.  However, the note to produce mean values for each acitivity and subject would suggest that each source field (i.e. <i>tBodyAcc-mean()-X</i>) would be averaged in its own column, producing a file that was still tidy (perhaps slightly less, so) while being WIDE.  

This corresponds to the discussion between options (a) and (c) in the general class forum:
<https://www.coursera.org/learn/data-cleaning/discussions/forums/h8cjA78DEeWtFA5RrsHG3Q/threads/-Cjtsip5Eea0DRLrrvCCTQ>

The distinction has also been discussed by David Hood on his wordpress site:
<https://thoughtfulbloke.wordpress.com/2015/09/09/getting-and-cleaning-the-assignment/>

Finally, Hadley Wickham notes in his paper on tidy data (<http://vita.had.co.nz/papers/tidy-data.pdf>) that several data set forms may be tidy, but that the final form is highly dependent on the question being asked.

As no specific analysis question has been posed, I have constructed the run_analysis.R script as a function which is capable of producing both a NARROW and a WIDE data set which meets the core tidy principles:

1.  Each variable forms a column.
2.  Each observation forms a row.
3.  Each type of observational unit forms a table.

(Note that 3 is not applicable to this assignment.)

As most individudals in the forum discussions noted above elected (a) as the proper interpretation, the default output of run_analysis() is a tidy data set in the WIDE format.  Note that the calculation of each variable mean is identical regardless of the chosen format.  Each is an average by activity and subject, the only difference between the two files is how the tidy data set is arranged.

### Selection of Analysis Variables

Mean and standard deviation related variables were identified using the ReadMe file provided with the raw data.  <i>-mean()</i> or <i>-std()</i> within their feature name.  We acknowledge that arguments exist for also including those with <i>meanFreq()</i> or angle features such as <i>gravityMean</i>.  We elected to remove such fields from consideration as the features_info.txt file noted that <i>meanFreq()</i> features were only used to "obtain a mean frequency" as opposed to being means in and of themselves.  Further, we noted that fields such as <i>gravityMean</i> were in fact angles as opposed to true means or standard deviations.

### Variable Naming Conventions

Review of the raw data file ReadMe provides a layout of how features were named.  The <i>t</i> in the feature, <i>tBodyAcc-mean()-X</i>, tells us that the measurement is scaled within the time <b>domain</b>, while BodyAcc tells us that the signal <b>source</b> is the movement of the phone <i>body</i> as detected by the <i>accelerometer</i> <b>sensor</b>.  Finally, <i>-mean()</i> tells us that this is a <i>mean</i> <b>calculation</b>, and <i>-x</i> tells us that the measurement pertains to the <b>direction</b> of the <i>x-axis</i>.  Finally, nearly every field is some measurement of acceleration, while other measure jerk, acceleration magnitudes, or jerk magnitudes.

#### WIDE Format

For output in the WIDE format, run_analysis produces the mean value of variables which have been named according to the above decomposition.  These descriptive names can nearly be read as sentences.  
For example:
<center>"mean.body.acceleration.time.x-axis.accelerometer"</center>

Would translate to:

<center>"MEAN phone BODY ACCELERATION, in the TIME domain, along the X-AXIS, as detected by the ACCELEROMETER."</center>

#### NARROW Format

Output in the NARROW format utilizes the same decomposition as the wide format, but adds the following categorical columns to the data set:

* <b>Calculation</b> - Type of calculation, either mean or standard deviation.
* <b>Source</b> - The source of the signal detected as determined by the Butterworth filtering process, either body or gravity.
* <b>Signal</b> - The type of signal being recorded or measured, acceleration, jerk, acceleration magnitude or jerk magnitude.
* <b>Domain</b> - The domain of the signal measurement, either time or frequency.
* <b>Direction</b> - The direction, if any, of the signal, x-axis, y-axis, z-axis, or no direction.
* <b>Sensor</b> - The device which detected or measured the signal, either accelerometer or gyroscope.
Mean values of each source column by subject and acitivity are then stored in the <b>measure</b> variable.

## Review of run_analysis.R

The following section details how we tackled each step of the assignment in the run_analysis() function.

0. Preliminaries
+ We begin our analysis by loading packages necessary for future steps: dplyr, tidyr, and checking the availability of the data set within a subset of our working directory.  If the data or directory are not present, then they are downloaded or created, respectively, and the zip file is extracted.  

+ Once this verification is complete, data tables from each needed file are loaded and a final check of the selection of WIDE or NARROW is made.  At this stage data tables for DATA, SUBJECTS, FEATURES and ACTIVITIES should all be available.

1. Merge the training and the test sets to create one data set.
+ Merging of the training and test sets is done using the bind_rows() function from the dplyr package.  Once training and tests sets have been merged, checks are done to verify that data set order has been maintained.  FInally a similar merging is conducted on data sets for subjects and activities.

2. Extract only the measurements on the mean and standard deviation for each measurement.

+ The grepl() function is used on the FEATURES data table to identify which measurements pertain to mean and standard deviation.  As described in the overview section this includes any features containing  <i>-mean()</i> or <i>-std()</i>.  This is then used to set which elements of the DATA set are to be retained.

3. Use descriptive activity names to name the activities in the data set

+ Activity names are mapped from the ACTIVITY data tables to the DATA set by use of dplyr's inner_join() function.  select() is then used to remove the activity number field from the set.

4. Appropriately labels the data set with descriptive variable names.

+ Descriptive variables are defined as outlined in the Overview section above.  The grepl() function is used to identify pertinent substrings of each feature to generate the descriptive label.  For NARROW sets, these then generate additional categorical variables needed to gather the set.  For WIDE sets, these are used to generate more descriptive variable names.

5. From the data set in step 4, create a second, independent tidy data set with the average of each variable for each activity and each subject.

+ The DATA set from step 4 is then run through a list of dplyr piping statements in order to calculate the appropriate mean values of each source variable.  
+ The difference between NARROW and WIDE options is in the group_by() statement of the piping stream.  We note that while the group_by() statement differs, the actual  calculations are identical.
