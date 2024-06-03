#!/bin/bash

# This script iterates through all the Google Cloud projects that the context user has access to and outputs a CSV file containing all Service Account Keys
# Run the script directly in the Google Cloud console

# Create CSV file
echo "project_id,sa_key_id,sa_name,sa_email,creation_date,expiration_date" > sa_keys.csv

# Get a list of all projects in the organization (depends on access rights)
projects=$(gcloud projects list --format='value(projectId)')

# Iterate through all projects
for project in $projects; do
    echo "Checking project: $project"

    # Get all service accounts in the current project (filter out the disabled ones)
    service_accounts=$(gcloud iam service-accounts list --project=$project --verbosity="error" --filter="disabled=false" --format="value(email)")

    # Iterate through all service accounts
    for service_account in $service_accounts; do
        # Get SA name
        sa_name=$(gcloud iam service-accounts describe $service_account --project=$project --format="value(displayName)")

        # Get all SA Keys (filter out the system managed ones)
        sa_keys=$(gcloud iam service-accounts keys list --iam-account=$service_account --project=$project --filter="keyType=user_managed" --format="value(name)")

        for sa_key in $sa_keys; do
            # Get SA creation date
            sa_key_created_at=$(date -d $(gcloud iam service-accounts keys list --iam-account=$service_account --filter="name:$sa_key" --format="value(validAfterTime)") +"%d.%m.%Y")
            
            # Get SA expiration date
            sa_key_expires_at=$(date -d $(gcloud iam service-accounts keys list --iam-account=$service_account --filter="name:$sa_key" --format="value(validBeforeTime)") +"%d.%m.%Y")

            echo "$project,$sa_key,$sa_name,$service_account,$sa_key_created_at,$sa_key_expires_at" >> sa_keys.csv
        done
    done
done
