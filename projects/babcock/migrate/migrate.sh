#!/bin/bash


java -XX:-UseGCOverheadLimit -Xmx2048m -cp /root/baraza/build/baraza.jar org.baraza.DB.BMigration migrate1.xml >> migrate.log &


