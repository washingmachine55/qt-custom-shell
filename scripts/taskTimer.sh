#!/bin/bash

commandToRun="$(~/.local/bin/barbtils tasks sessions 'Task timer' -j | jq '.task.total' --color-output -r)"
echo "Task timer: $commandToRun"
