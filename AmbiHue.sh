#!/bin/bash

host=dalights.cs.dartmouth.edu
token=newdeveloper
numlights=15
argcount=0
args=( "$@" )

COUNTER=1
while [  $COUNTER -le $numlights ]; do
	#echo The counter is $COUNTER
	#echo curl --request PUT --data "{\"on\": true,\"bri\":${args[$argcount+2]},\"sat\":${args[$argcount+1]},\"hue\":${args[$argcount]},\"effect\":\"none\"}" http://$host/api/$token/lights/$COUNTER/state 
	curl --request PUT --data "{\"on\": true,\"bri\":${args[$argcount+2]},\"sat\":${args[$argcount+1]},\"hue\":${args[$argcount]},\"effect\":\"none\"}" http://$host/api/$token/lights/$COUNTER/state  
	let COUNTER=COUNTER+1 
	let argcount=argcount+3
done

