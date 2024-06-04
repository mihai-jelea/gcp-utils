#!/bin/bash

# This script iterates through all the Google Cloud projects that the context user has access to and outputs a CSV file containing all VM Disks and
# information on their snapshot schedule configuration
# Run the script directly in the Google Cloud console

# Define the name of the output CSV file
output_file="gce_disks_with_snapshot_schedule.csv"

# Write the header to the CSV file
echo "project,disk_name,region_zone,disk_type,kind,disk_size_gb,status,snapshot_enabled,frequency,storage_location,retention_days" >$output_file

# Fetch all projects
#projects=$(gcloud projects list --format="value(projectId)")
projects="mihai-demo"

# Iterate through each project
for project in $projects; do
    echo "Checking project: $project"

    # Check zonal Compute Engine disks
    # -----------------------------------------------------------------------------------------------------------------------------
    # Array to store the list of zones where compute disks have been deployed in the current project
    used_zones=()

    # Fetch zones for deployed Compute Engine disks
    zone_list=$(gcloud compute disks list --project="$project" --format="value(zone)")

    # Extract zone names
    for zone in $zone_list; do
        zone_name=$(echo "$zone" | awk -F'/' '{print $NF}')
        used_zones+=("$zone_name")
    done

    # Remove duplicates and print the unique zone names
    zones=$(echo ${used_zones[@]} | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo " -> Found zonal disks in: $zones"

    # Iterate through each zone
    for zone in $zones; do
        echo " --> Checking zone: $zone"

        # List all disks in the current zone
        disks=$(gcloud compute disks list --project=$project --zones=$zone --format="csv[no-heading](name,type,sizeGb,kind,status,selfLink)" --verbosity="error")

        # Check if there are any disks
        if [ -n "$disks" ]; then
            # Process each disk
            while IFS=',' read -r name type size kind status selfLink; do
                # Check if the disk has a resource policy (snapshot schedule)
                resource_policy=$(gcloud compute disks describe "$name" --project=$project --zone=$zone --format="value(resourcePolicies)" --verbosity="error")

                # Determine if a snapshot schedule exists
                if [ -n "$resource_policy" ]; then
                    snapshot_schedule="yes"
                    region=$(echo $zone | sed 's/-[a-z]$//')
                    schedule=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region="$region" --format="value(snapshotSchedulePolicy.schedule.dailySchedule)")
                    if [ -n "$schedule" ]; then
                        frequency="daily"
                    else
                        schedule=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region="$region" --format="value(snapshotSchedulePolicy.schedule.weeklySchedule)")
                        if [ -n "$schedule" ]; then
                            frequency="weekly"
                        else
                            frequency="hourly"
                        fi
                    fi
                    storage_location=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region "$region" --format="value(snapshotSchedulePolicy.snapshotProperties.storageLocations)")
                    retention_days=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region "$region" --format="value(snapshotSchedulePolicy.retentionPolicy.maxRetentionDays)")
                else
                    snapshot_schedule="no"
                    frequency=""
                    storage_location=""
                    retention_days=""
                fi

                # Append the project, zone, and disk details to the CSV file
                echo "$project,$name,$zone,$type,$kind,$size,$status,$snapshot_schedule,$frequency,$storage_location,$retention_days" >>$output_file
            done <<<"$disks"
        fi
    done

    # Check regional Compute Engine disks
    # -----------------------------------------------------------------------------------------------------------------------------
    # Array to store the list of zones where compute disks have been deployed in the current project
    used_regions=()

    # Fetch regions for deployed Compute Engine disks
    region_list=$(gcloud compute disks list --project="$project" --format="value(region)")

    # Extract zone names
    for region in $region_list; do
        region_name=$(echo "$region" | awk -F'/' '{print $NF}')
        used_regions+=("$region_name")
    done

    # Remove duplicates and print the unique zone names
    regions=$(echo ${used_regions[@]} | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo " -> Found regional disks in: $regions"

    # Iterate through each zone
    for region in $regions; do
        echo " --> Checking region: $region"

        # List all disks in the current zone
        disks=$(gcloud compute disks list --project=$project --regions=$region --format="csv[no-heading](name,type,sizeGb,kind,status,selfLink)" --verbosity="error")

        # Check if there are any disks
        if [ -n "$disks" ]; then
            # Process each disk
            while IFS=',' read -r name type size kind status selfLink; do
                # Check if the disk has a resource policy (snapshot schedule)
                resource_policy=$(gcloud compute disks describe "$name" --project=$project --region=$region --format="value(resourcePolicies)" --verbosity="error")

                # Determine if a snapshot schedule exists
                if [ -n "$resource_policy" ]; then
                    snapshot_schedule="yes"
                    schedule=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region="$region" --format="value(snapshotSchedulePolicy.schedule.dailySchedule)")
                    if [ -n "$schedule" ]; then
                        frequency="daily"
                    else
                        schedule=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region="$region" --format="value(snapshotSchedulePolicy.schedule.weeklySchedule)")
                        if [ -n "$schedule" ]; then
                            frequency="weekly"
                        else
                            frequency="hourly"
                        fi
                    fi
                    storage_location=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region "$region" --format="value(snapshotSchedulePolicy.snapshotProperties.storageLocations)")
                    retention_days=$(gcloud compute resource-policies describe "$(basename "$resource_policy")" --region "$region" --format="value(snapshotSchedulePolicy.retentionPolicy.maxRetentionDays)")
                else
                    snapshot_schedule="no"
                    frequency=""
                    storage_location=""
                    retention_days=""
                fi

                # Append the project, zone, and disk details to the CSV file
                echo "$project,$name,$region,$type,$kind,$size,$status,$snapshot_schedule,$frequency,$storage_location,$retention_days" >>$output_file
            done <<<"$disks"
        fi
    done
done

echo "Finished listing disks for all projects. Output written to $output_file"
