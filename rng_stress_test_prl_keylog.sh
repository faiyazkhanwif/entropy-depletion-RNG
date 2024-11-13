#!/bin/bash

# Parameters
NUM_CALLS=10000          # Total calls per process
KEY_SIZE=256             # Key size in bytes for secure cryptographic operations
PARALLEL_PROCESSES=10    # Number of parallel processes
ERROR_LOG_FILE="error_log.txt"
KEY_LOG_FILE="key_log.txt"
ENTROPY_LOG_FILE="entropy_log.txt"
> $ERROR_LOG_FILE
> $KEY_LOG_FILE
> $ENTROPY_LOG_FILE

# Function to test cryptographic operations and log potential issues
test_crypto_operations() {
    for i in $(seq 1 $NUM_CALLS); do
        # Generate a secure key using OpenSSL, capturing any errors
        key=$(openssl rand -hex $KEY_SIZE 2>> $ERROR_LOG_FILE)
        
        # If OpenSSL fails, log an error message
        if [ $? -ne 0 ]; then
            echo "Process $$ - Iteration $i - Error: Cryptographic operation failed due to low entropy" >> $ERROR_LOG_FILE
        fi

        # Log each generated key to check for duplicate or weak keys
        echo "$key" >> $KEY_LOG_FILE
        
        # Read bytes directly from /dev/random to drain entropy
        head -c $KEY_SIZE /dev/random > /dev/null 2>&1

        # Log the current entropy level
        entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        echo "Process $$ - Iteration $i - Entropy: $entropy" >> $ENTROPY_LOG_FILE
    done
}

echo "Starting RNG reliability test with $PARALLEL_PROCESSES parallel processes..."

# Start multiple parallel processes to test cryptographic reliability under low entropy
for _ in $(seq 1 $PARALLEL_PROCESSES); do
    test_crypto_operations &
done

# Wait for all background processes to finish
wait

echo "Test complete. Check $ERROR_LOG_FILE for cryptographic errors, $KEY_LOG_FILE for generated keys, and $ENTROPY_LOG_FILE for entropy levels."