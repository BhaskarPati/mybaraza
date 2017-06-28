#!/bin/bash

cd $(dirname $0)


TOMCAT_PATH=/Users/henriquedn/Lab/Apache/tomcat
WEBAPP_NAME=bunson

export PATH=/Library/Java/JavaVirtualMachines/jdk1.7.0_71.jdk/Contents/Home/bin/
export CLASSPATH=$TOMCAT_PATH/lib/servlet-api.jar 
export CLASSPATH=$CLASSPATH:$TOMCAT_PATH/webapps/$WEBAPP_NAME/WEB-INF/lib/baraza.jar
export CLASSPATH=$CLASSPATH:$TOMCAT_PATH/webapps/$WEBAPP_NAME/WEB-INF/lib/json_simple-1.1.jar
export CLASSPATH=$CLASSPATH:$TOMCAT_PATH/webapps/$WEBAPP_NAME/WEB-INF/classes/

echo 'Compiling.......'
#javac ProcessPNRXML.java
javac ProcessRequestServlet.java
#javac DriverRequest.java
#javac PushToTransportServlet.java
#javac ProcessPNRXMLToSegments.java
#javac ESync.java
#javac ETravelService.java
echo 'Compile Done'
