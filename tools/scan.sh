#!/bin/sh

PERSISTENCE_HOST=${PERSISTENCE_HOST:-persistence}

if [ $# -le 1 ]; then
    echo "No targets and/or checktypes arguments provided"
    echo "Targets should look like: 'example.com;1.1.1.1;python:3.4-alpine;example.com/my-site'"
    echo "Checktypes should look like: 'vulcan-http-headers;vulcan-http-exposed-resources;vulcan-trivy;vulcan-tls'"
    echo "examples:"
    echo "      scan.sh \"example.com\" \"vulcan-tls,vulcan-http-headers\""
    echo "      scan.sh \"example.com\" \"all\""
    echo "      scan.sh \"example.com\" \"all-experimental\""
    exit 1
fi

# Clean previous targets and checktypes (if any)
cat /dev/null > targets
cat /dev/null > checktypes

ifs_backup=$IFS
export IFS=";"

for target in $1; do
    echo "$target" >> targets
done

# Reaload checktype list
for checktype in $2; do
    if [ "$checktype" = "all" ]; then
        curl "http://${PERSISTENCE_HOST}/v1/checktypes" | \
        jq -r '.checktypes[].name' | sort | uniq | grep -v "experimental" > checktypes
        break
    fi
    if [ "$checktype" = "all-experimental" ]; then
        curl "http://${PERSISTENCE_HOST}/v1/checktypes" | \
        jq -r '.checktypes[].name' | sort | uniq | grep "experimental" > checktypes
        break
    fi
    echo "$checktype" >> checktypes
done

export IFS=$ifs_backup

echo "# Creating scan for targets:"
cat targets
echo "# Running the following checktypes:"
cat checktypes

vulcan-core-cli -s http -H "${PERSISTENCE_HOST}" scan targets checktypes > scan_output

scan_id=$(tail -1 scan_output | sed 's/\/tmp\///g' | sed 's/\.gob//g')
echo "# ScanID: ${scan_id}"

echo "Starting scan"
sleep 1
vulcan-core-cli -s http -H "${PERSISTENCE_HOST}" monitor "$(tail -1 scan_output)"
echo "Scan finished"

echo "Generating report"
vulcan-security-overview -config config.toml -scan-id "$scan_id" -team-id VulcanTeam -team-name VulcanReport
