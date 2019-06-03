#!/bin/bash
#PATH=/usr/bin
while [ "$x" == "" ]; do
 l=`/usr/bin/aplay -l | grep périphérique | wc -l`
 if [ "$l" != "0" ]; then
   echo Found sound cards
   x="done"
/bin/bash /usr/local/bin/defaultvolume.sh
 else
  sleep 2
 fi
done
