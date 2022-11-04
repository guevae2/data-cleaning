## data cleaning employee

install.packages('tidyverse')

library( tidyverse)

## 1. load csv file
ros <-read.csv('roster.csv')

## 1.1 check the file
head(ros)
str(ros)
summary(ros)

# 2. Change hire_date format to date only

ros$hire_date <-as.Date(ros$hire_date, "%m/%d/%Y")

## 2.1 Check hire_date
ros

## 3. create a new column for emp_number and and sup_inital

## 3.1 creating emp_number extracting number from emp_email
ros <-ros %>% 
  separate(emp_email,into = 'emp_number',sep = '@',remove = F)

## 3.2 creating sup_ini extracting number from emp_email

ros <-ros %>% 
  separate(sup_email,into = 'sup_initial',sep = '@',remove = F)


## 4. NA values

## 4.1 checking for NA values

is.na(ros)
### the dataset shows blank values in the Org_name column but R does not identify it as NA.


## 4.2 Changing blank values to NA

ros$Org_Name <-ifelse(ros$Org_Name == "", NA, ros$Org_Name)

## Let's check again for NA rows
summary(ros)

## 4.3 Filling in NA values with the appropriate Org_Name based from Org_Code

## 4.3.1 Let's check the Org_Name per Org_Code

o <-ros %>% 
  select(Org_Code, Org_Name) %>% 
  group_by(Org_Name) %>% 
  distinct(Org_Code) %>% 
  drop_na(Org_Name)


## 4.3.2 Join data frames


ros <- left_join(ros,o,"Org_Code")

ros

## 4.3.3 lookup the value to the joined column

ros$Org_Name<- ifelse(is.na(ros$Org_Name.x), ros$Org_Name.y, ros$Org_Name.x)


## 4.3.4 removing unnecessary columns
ros <- ros %>% 
        select(hire_date, emp_number, emp_email, sup_initial, sup_email, Org_Code, Org_Name)


## 5. Misspelled values in the data frame
any(is.na(ros))

i <-ros %>% 
  select(sup_initial,sup_email) %>% 
  group_by(sup_email) %>% 
  distinct(sup_initial)

                                                                                                                                      i
## 5.1 Value Mapping
i[65,1]  ## ty& \"

i[65,2] ## ty& \"@sup.com\"


## 5.2 Replacing the errant values

i['sup_initial'][i['sup_initial']== 'ty& \"' ] <- 'ty'

i['sup_email'][i['sup_email'] == 'ty& \"@sup.com\"'] <- 'ty@sup.com'

## 6. capitalize characters in sup_inital
ros$sup_initial <-toupper(ros$sup_initial)

## Completed the cleaning process.

## Optional Exporting file
write.csv(ros,'your file path/file name,csv', row.names = F)

getwd()
