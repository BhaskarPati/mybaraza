#!/bin/bash

psql -q ueab < pre.updates.sql

java -XX:-UseGCOverheadLimit -Xmx2048m -cp /root/baraza/build/baraza.jar org.baraza.DB.BMigration migrate.xml

psql -q ueab_new < post.update.sql

