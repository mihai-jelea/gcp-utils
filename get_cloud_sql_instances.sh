#!/bin/bash

# This script iterates through all the Google Cloud projects that the context user has access to and outputs a CSV file containing all Cloud SQL instances and
# information on their backup configuration
# Run the script directly in the Google Cloud console

# Create CSV file
echo "project,name,created_at,region,tier,database_version,public_ip,status,availability_type,backup_enabled,retained_backups,backup_starttime,binary_log_enabled,deletion_protection" >cloud_sql_instances.csv

# Get a list of all projects in the organization (depends on access rights)
projects=$(gcloud projects list --format='value(projectId)')

# Iterate through all projects
for project in $projects; do
    echo "Checking project: $project"

    # Get all CloudSQL instances in project
    gcloud sql instances list --project="$project" --quiet --format="csv(project,name,createTime,region,settings.tier,databaseVersion,ipAddresses.ipAddress,state,settings.availabilityType,settings.backupConfiguration.enabled,settings.backupConfiguration.backupRetentionSettings.retainedBackups,settings.backupConfiguration.startTime,settings.backupConfiguration.binaryLogEnabled,settings.deletionProtectionEnabled)" | tail -n +2 | while IFS="," read -r project name created_at region tier db_version ip_address state availability_type backup_enabled retained_backups backup_starttime binary_log_enabled deletion_protection; do

        # Handle missing public IP
        if [ -z "$ip_address" ]; then
            ip_address="None"
        fi

        # Output the instance details
        echo "$project,$name,${created_at%T*},$region,$tier,$db_version,$ip_address,$state,$availability_type,$backup_enabled,$retained_backups,$backup_starttime,$binary_log_enabled,$deletion_protection" >>cloud_sql_instances.csv

    done
done