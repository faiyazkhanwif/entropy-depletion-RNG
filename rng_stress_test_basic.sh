#!/bin/bash

# Parameters
NUM_CALLS=10000 # Adjust based on load requirements
KEY_SIZE=256 # Key size for secure cryptographic operations

# Log file for entropy levels
LOG_FILE="entropy_log.txt"
> $LOG_FILE

echo "Starting RNG stress test with $NUM_CALLS iterations..."

for i in $(seq 1 $NUM_CALLS); do
    # Generate a secure key
    #openssl rand -hex $KEY_SIZE > /dev/null 2>&1
    
    # Generate a secure key using OpenSSL, capturing any errors
    key=$(openssl rand -hex $KEY_SIZE 2>> $ERROR_LOG_FILE)
    
    # If OpenSSL fails, log an error message
    if [ $? -ne 0 ]; then
        echo "Process $$ - Iteration $i - Error: Cryptographic operation failed due to low entropy" >> $ERROR_LOG_FILE
    fi

    # Log each generated key to check for duplicate or weak keys
    echo "$key" >> $KEY_LOG_FILE


    # Log the current entropy level
    entropy=$(cat /proc/sys/kernel/random/entropy_avail)
    echo "Iteration $i - Entropy: $entropy" >> $LOG_FILE

    # Optional: Introduce a small delay to simulate realistic API call intervals
    sleep 0.01
done

echo "Test complete. Check $LOG_FILE for entropy logs."