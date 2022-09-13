#!/bin/bash

sleep 5s

PORT=$(kubectl -n default get svc ${serviceName} -o json | jq '.spec.ports[].nodePort' )

echo $PORT
# echo $applicationURL:$PORT/$applicationURI
appAddrs=$(echo $applicationURL:$PORT$applicationURI)
echo $appAddrs

if [[ ! -z "$PORT" ]]; then
    response=$(curl -s $appAddrs)
    http_code=$(curl -s -o /dev/null -w "%{http_code}" $appAddrs)

    if [[ "$response" == 100 ]]; then
        echo "Increment Test Passed"
    else
        echo "Increment Test Failed"
        exit 1
    fi

    if [[ "$http_code" == 200 ]]; then
        echo "HTTP Status Code Test Passed"
    else
        echo "HTTP Status Code Failed"
        exit 1
    fi

else
    echo "The Service Does Not Have a NodePort"
    exit 1
fi