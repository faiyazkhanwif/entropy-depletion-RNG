#!/bin/bash

LOG_FILE="recovery_log.txt"
> $LOG_FILE

for i in $(seq 1 600); do  # Monitor for 10 minutes = 600 seconds
    entropy=$(cat /proc/sys/kernel/random/entropy_avail)
    echo "Second $i - Entropy: $entropy" >> $LOG_FILE
    sleep 1
done
