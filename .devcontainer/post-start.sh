#!/bin/bash

# this runs each time the container starts

echo "$(date)    post-start start" >> ~/status

echo "$(date)    Update azure cli" >> ~/status
az upgrade --yes
az extension update --name aks-preview
az --version >> ~/status 

echo "$(date)    Turn off Skaffold metric collection " >> ~/status
skaffold config set --global collect-metrics false

echo "$(date)    post-start complete" >> ~/status