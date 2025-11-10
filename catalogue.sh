#!/bin/bash

appname=catalogue
source ./common.sh
check_root

check_roboshop_user
app_setup
nodejs_setup

systemd_setup

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copying mongod repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "installing mongodb-client"

mongosh --host mongodb.rajeshit.space </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "loading data into catalogue"


print_time