#!/bin/bash

cd $(dirname $0)

APP_NAME=bunson
WEBAPP_NAME=bunson
BARAZA_PATH=/Users/henriquedn/Lab/BARAZA/baraza
TOMCAT_PATH=/Users/henriquedn/Lab/Apache/tomcat/webapps

REMOTE_WEBAPP_NAME=bunson
REMOTE_USER=root
REMOTE_SERVER=62.24.116.56
REMOTE_TOMCAT_PATH=/opt/tomcat/webapps/

echo 'Copying Xml...'
cp $BARAZA_PATH/projects/$APP_NAME/configs/$APP_NAME.xml $TOMCAT_PATH/$WEBAPP_NAME/WEB-INF/configs/

X1="y"
X2="n"
echo "Copy XML to REMOTE Server? (y/n)"
read option

if [ "$option" = $X1 ]; then
    echo 'Copying XML to .......'$REMOTE_SERVER
    scp $BARAZA_PATH/projects/$APP_NAME/configs/$APP_NAME.xml $REMOTE_USER@$REMOTE_SERVER:$REMOTE_TOMCAT_PATH/$REMOTE_WEBAPP_NAME/WEB-INF/configs/
elif [ "$option" = $X2 ]; then
    echo "XML to REMOTE server ignored"
fi



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

P1="y"
P2="n"
echo "Copy REPORTS to REMOTE Server? (y/n)"
read option

if [ "$option" = $P1 ]; then
    echo 'Copying XML to .......'$REMOTE_SERVER
    scp $BARAZA_PATH/projects/$APP_NAME/reports/*.* $REMOTE_USER@$REMOTE_SERVER:$REMOTE_TOMCAT_PATH/$REMOTE_WEBAPP_NAME/reports/
    echo 'Finished REPORTS Copying to REMOTE Server'
elif [ "$option" = $P2 ]; then
    echo "XML to REMOTE server ignored"
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

echo "Copy baraza.jar to REMOTE Server? (y/n)"
read option

if [ "$option" = $S1 ]; then
    echo 'Copying baraza.jar to .......'
    scp $BARAZA_PATH/build/baraza.jar $REMOTE_USER@$REMOTE_SERVER:$REMOTE_TOMCAT_PATH/$REMOTE_WEBAPP_NAME/WEB-INF/lib/
    echo 'Finished Copying to REMOTE Server'
elif [ "$option" = $S2 ]; then
    echo "baraza.jar to REMOTE server ignored"
fi


