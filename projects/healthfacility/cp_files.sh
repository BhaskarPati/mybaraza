#!/bin/bash

cd $(dirname $0)

APP_NAME=healthfacility
WEBAPP_NAME=healthfacility
BARAZA_PATH=/Users/henriquedn/Lab/Repo/baraza_projects/baraza
TOMCAT_PATH=~/Lab/Apache/tomcat/webapps

echo 'Copying Xml...'
cp $BARAZA_PATH/projects/$APP_NAME/configs/$APP_NAME.xml $TOMCAT_PATH/$WEBAPP_NAME/WEB-INF/configs/



R1="y"
R2="n"

echo "Copy Reports? (y/n)"
read option

if [ "$option" = $R1 ]; then
    echo 'Copying Reports....'
    cp $BARAZA_PATH/projects/$APP_NAME/reports/*.* $TOMCAT_PATH/$WEBAPP_NAME/reports/
elif [ "$option" = $R2 ]; then
    echo "Reports ignored"
fi


S1="y"
S2="n"

echo "Copy baraza.jar? (y/n)"
read option

if [ "$option" = $S1 ]; then
    echo 'Copying baraza.jar.......'
    cp $BARAZA_PATH/build/baraza.jar  $TOMCAT_PATH/$WEBAPP_NAME/WEB-INF/lib/
elif [ "$option" = $S2 ]; then
    echo "baraza.jar ignored"
fi

echo 'Finished'
