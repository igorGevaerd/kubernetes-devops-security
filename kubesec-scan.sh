#!/bin/bash

scan_result=$(curl -sSX POST --data-binary @"k8s_deployment_service.yaml" https://v2.kubesec.io/scan)

echo $(echo ${scan_result} | jq '.')

scan_message=$(echo ${scan_result} | jq '.[0].message' -r)
scan_score=$(echo ${scan_result} | jq '.[0].score')

if [[ "${scan_score}" -ge 5 ]];then
    echo "Score is $scan_score"
    echo "Kubesec Scan - $scan_message"
else
    echo "Score is $scan_score, which is less than or equal to 5."
    echo "Scanning Kuberetes Resources has failed"
    exit 1
fi