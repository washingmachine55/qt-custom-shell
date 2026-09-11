#!/bin/bash

commandToRun="$(~/.local/bin/barbtils tasks sessions 'Kixmon timer' -j | jq '.task.total' --color-output -r)"
echo "Task timer: $commandToRun"
