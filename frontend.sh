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



dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling nginx version"


dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling the nginx version"


dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing the nginx"


systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "enabling and starting the nginx"


rm -rf /usr/share/nginx/html/* 
VALIDATE $? "removing default index.html content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading nginx zip file"

cd /usr/share/nginx/html 
VALIDATE $? "changing directory to html folder"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzipping the nginx zip file"


cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "copying the our nginx conf file"


systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restating the nginx"


