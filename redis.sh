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


dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "disabling redis default version"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling redis 7 version"


dnf install redis -y &>>$LOG_FILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected/ c protected-mode no' /etc/redis/redis.conf &>>$LOG_FILE
VALIDATE $? "changing local connection to remote connection and disabling protected mode"


systemctl enable redis 
systemctl start redis 
VALIDATE $? "Enabling and starting mysql serice"



SCRIPT_END=$(date +%s)
TOTAL_TIME=$($SCRIPT_END-$SCRIPT_START)
echo -e "Total time taken for installation: $G $TOTAL_TIME $N"
