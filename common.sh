#!/bin/bash
SCRIPT_START=$(date +%s)
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


#checking root user or not
check_root() {
        id roboshop &>>$LOG_FILE
        if [ $USERID -ne 0 ]
        then
            echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
            exit 1 #give other than 0 upto 127
        else
            echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
        fi
}

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



check_roboshop_user() {
    id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]
    then
        echo -e " user is not existed ..$G so creating $N"
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        VALIDATE $? "creating roboshop systemuser"
    else
        echo -e " roboshop user is already existed..$Y so skipping $N"
    fi 
}


app_setup() {
    
    mkdir -p /app 
    VALIDATE $? "creating app directory"

    curl -o /tmp/$appname.zip https://roboshop-artifacts.s3.amazonaws.com/$appname-v3.zip &>>$LOG_FILE
    VALIDATE $? "downloading the $appname zip file"


    rm -rf /app/*
    cd /app 
    unzip /tmp/$appname.zip &>>$LOG_FILE
    VALIDATE $? "$appname the zip file"
}


nodejs_setup() {
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "diabling nodejs module"

    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "enabling the nodejs module"

    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "installing nodejs"

    npm install &>>$LOG_FILE
    VALIDATE $? "installing dependencies"
}


systemd_setup(){
    cp $SCRIPT_DIR/$appname.service /etc/systemd/system/$appname.service &>>$LOG_FILE
    VALIDATE $? "copying service file and creating systemctl"

    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable $appname 
    systemctl start $appname 
    VALIDATE $? "daemon-reload,enabling and starting the $appname service"
}


print_time(){
    SCRIPT_END=$(date +%s)
    TOTAL_TIME=$(($SCRIPT_END-$SCRIPT_START))
    echo -e "Total time taken for installation: $G $TOTAL_TIME sec $N"
}




