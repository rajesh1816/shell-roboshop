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



dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "diabling nodejs module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling the nodejs module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs"


id roboshop
if [ $? -ne 0 ]
then
    echo -e " user is not existed ..$G so creating $N"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "creating roboshop systemuser"
else
    echo -e "$Y roboshop user is already existed..so skipping $N"
fi

mkdir /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading the catalogue zip file"

cd /app 
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzipping the zip file"


npm install &>>$LOG_FILE
VALIDATE $? "installing dependencies"


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "copying service file and creating systemctl"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue 
systemctl start catalogue 
VALIDATE $? "daemon-reload,enabling and starting the catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copying mongod repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb-client"

mongosh --host mongodb.rajeshit.space </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "loading data into catalogue"