#!/bin/bash
# This script would get the timer name and total running time of the timer set in barbtils with the longest running time

# taskTime="$(~/.local/bin/barbtils tasks ls --running --json | jq -r '. | .tasks | map(pick(.name, .total_seconds, .total, .running)) | del(.[] | select(.running == false)) | max_by(.total_seconds) | .total')"
# taskName="$(~/.local/bin/barbtils tasks ls --running --json | jq -r '. | .tasks | map(pick(.name, .total_seconds, .total, .running)) | del(.[] | select(.running == false)) | max_by(.total_seconds) | .name')"

sourceData="$(~/.local/bin/barbtils tasks ls --json)"
query="$(jq -r '. | .tasks | map(pick(.name, .total_seconds, .total, .running)) | del(.[] | select(.running == false)) | max_by(.total_seconds)' <<< $sourceData)"

eval "$(jq -r '@sh "export taskName=\(.name) taskTime=\(.total)"' <<< $query)"

echo "$taskName: $taskTime"
