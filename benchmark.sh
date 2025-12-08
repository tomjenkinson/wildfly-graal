#!/bin/bash

finish=$((`date +%s`+1*60))
for (( i=`date +%s`; i <= $finish; i=`date +%s` )) do
  for j in $(seq 1 10); do
    wget http://127.0.0.1:8080/ > wget-out.$j.$i &
  done
  ps -axm -o rss,comm > size.$i
done
