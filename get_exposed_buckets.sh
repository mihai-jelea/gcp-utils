#!/bin/bash

# This script iterates through all the Google Cloud projects that the context user has access to and outputs a CSV file containing all Cloud Storage buckets and 
# information on their access configurations
# Run the script directly in the Google Cloud console

## Create CSV file
echo "project_id,bucket_id,allUsers_role,uniform_ac" >exposed_buckets.csv

## Get a list of all projects you have access to
projects=$(gcloud projects list --format='value(projectId)')

## Iterate through all projects
for project in $projects; do
    echo "Checking project: $project"

    # Get all buckets in the project
    buckets=$(gsutil ls -p "$project")

    for bucket in $buckets; do
        # Get IAM policy of the bucket in JSON format
        iam_policy=$(gcloud storage buckets get-iam-policy $bucket --project=$project --format=json)

        # Get uniform bucket-level access status
        bucket_access_status=$(gcloud storage buckets describe $bucket --project=$project | grep -oP 'uniform_bucket_level_access:\s+\K\w+')

        # Check for "allUsers" with public roles
        if echo $iam_policy | grep -q '"allUsers"' || [[ $bucket_access_status == false ]]; then
            # Append to CSV file
            echo "$project,$bucket,$(echo $iam_policy | grep -oP '"members": \[\s*"allUsers"[^}]*\}' | grep -oP '(?<="role": "roles/)[^"]*(?=")'),$bucket_access_status" >>exposed_buckets.csv
        fi
    done
done
