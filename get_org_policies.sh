#!/bin/bash

# This file contains 3 separate scripts that extract the organization policies at org, folder and project level and outputs them in CSV files
# Run the scripts directly in the Google Cloud console

# Set Org ID
export ORG_ID=$(gcloud organizations list --format 'value(ID)')

# Get Enabled Policies at Org Level
gcloud resource-manager org-policies list --organization=$ORG_ID --format="csv(constraint)" >organization_policies.csv

# Get Enabled Policies for all folders under the Org Level
echo "folder_id, constraint" >folder_policies.csv
for folder in $(gcloud resource-manager folders list --organization $ORG_ID --format='value(name)'); do
    export FOLDER=$folder
    echo "----------------------------------------------"
    echo "Getting Org policies for - " $FOLDER
    for constraint in $(gcloud resource-manager org-policies list --folder=$FOLDER --format='value(constraint.basename())'); do
        echo "$FOLDER, $(gcloud resource-manager org-policies describe $constraint --folder=$FOLDER --format="value(constraint.basename())")" >>folder_policies.csv
    done
done

# Get Enabled Policies for all Projects
echo "project_id, constraint" >project_policies.csv
for PROJECT in $(gcloud asset search-all-resources --scope organizations/$ORG_ID --asset-types='cloudresourcemanager.googleapis.com/Project' --format='value(name.basename())'); do
    echo "----------------------------------------------"
    echo "Getting Org policies for - " $PROJECT
    for constraint in $(gcloud resource-manager org-policies list --project=$PROJECT --format='value(constraint.basename())'); do
        echo "$PROJECT, $(gcloud resource-manager org-policies describe $constraint --project=$PROJECT --format="value(constraint.basename())")" >>project_policies.csv
    done
done
