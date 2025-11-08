#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
SCRIPT_START=$(date +%s)



mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
fi

# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e " $2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e " $2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}


dnf install maven -y &>>$LOG_FILE
VALIDATE $? "installing maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e " user is not existed ..$G so creating $N"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating roboshop systemuser"
else
    echo -e " roboshop user is already existed..$Y so skipping $N"
fi



mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the shipping zip file"


rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping the zip file"


mvn clean package &>>$LOG_FILE
VALIDATE $? "packaging the code"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving and renaming the jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copying shiiping service to /etc location for setting systemctl"


systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon-reload"

systemctl enable shipping  &>>$LOG_FILE
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Enabling and stating the shipping service"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql"


mysql -h mysql.rajeshit.space -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.rajeshit.space -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.rajeshit.space -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.daws84s.space -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi


SCRIPT_END=$(date +%s)
TOTAL_TIME=$(($SCRIPT_END-$SCRIPT_START))
echo -e "Total time taken for installation: $G $TOTAL_TIME sec $N"