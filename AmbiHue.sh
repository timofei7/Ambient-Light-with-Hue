#!/bin/bash

curl --request PUT --data "{\"on\": true,\"bri\":$3,\"sat\":$2,\"hue\":$1,\"effect\":\"none\"}" http://YourIP/api/YourToken/lights/1/state
curl --request PUT --data "{\"on\": true,\"bri\":$6,\"sat\":$5,\"hue\":$4,\"effect\":\"none\"}" http://YourIP/api/YourToken/lights/2/state
curl --request PUT --data "{\"on\": true,\"bri\":$9,\"sat\":$8,\"hue\":$7,\"effect\":\"none\"}" http://YourIP/api/YourToken/lights/3/state
