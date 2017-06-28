#!/bin/bash

cd $(dirname $0)

echo 'Copying Xml...'
cp ~/Lab/Repo/baraza_projects/baraza/projects/mobilehealth/configs/mobilehealth.xml ~/Lab/Apache/tomcat/webapps/mpamanech/WEB-INF/configs/
echo 'Copying Reports....'
cp ~/Lab/Repo/baraza_projects/baraza/projects/mobilehealth/reports/*.* ~/Lab/Apache/tomcat/webapps/mpamanech/reports/
echo 'Done...'