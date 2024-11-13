#!/bin/bash

# Parameters
NUM_CALLS=10000           # Total calls per process
KEY_SIZE=256              # Key size in bytes for secure cryptographic operations
PARALLEL_PROCESSES=10     # Number of parallel processes
ERROR_LOG_FILE="error_log.txt"
KEY_LOG_FILE="key_log.txt"
ENTROPY_LOG_FILE="entropy_log.txt"
WAIT_LOG_FILE="wait_log.txt"  # New log file to track wait durations
> $ERROR_LOG_FILE
> $KEY_LOG_FILE
> $ENTROPY_LOG_FILE
> $WAIT_LOG_FILE

# Function to test cryptographic operations and log potential issues
test_crypto_operations() {
    for i in $(seq 1 $NUM_CALLS); do
        # Check initial entropy level
        initial_entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        echo "Process $$ - Iteration $i - Initial Entropy: $initial_entropy" >> $ENTROPY_LOG_FILE
        
        # Start time measurement
        start_time=$(date +%s%3N)  # Get current time in milliseconds

        # Generate a secure key - use any one of the following
        # Using /dev/random -> to enforce strict reliance on system entropy
        key=$(head -c $KEY_SIZE /dev/random | openssl enc -base64 2>> $ERROR_LOG_FILE)
        # Using /dev/urandom
        #key=$(head -c $KEY_SIZE /dev/urandom | openssl enc -base64 2>> $ERROR_LOG_FILE)
        # Using openssl
        #key=$(openssl rand -hex $KEY_SIZE 2>> $ERROR_LOG_FILE)
        # Using openssl -> RSA
        #key=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out /dev/null 2>> $ERROR_LOG_FILE)

        # End time measurement
        end_time=$(date +%s%3N)    # Get current time in milliseconds
        duration=$((end_time - start_time))

        # Log the wait duration only if there was a noticeable delay
        if [ "$duration" -gt 0 ]; then
            echo "Process $$ - Iteration $i - Wait Time: ${duration}ms" >> $WAIT_LOG_FILE
        fi

        # If OpenSSL fails, log an error message
        if [ $? -ne 0 ]; then
            echo "Process $$ - Iteration $i - Error: Cryptographic operation failed due to low entropy" >> $ERROR_LOG_FILE
        fi

        # Log each generated key
        echo "$key" >> $KEY_LOG_FILE

        # Log the final entropy level after the operation
        final_entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        echo "Process $$ - Iteration $i - Final Entropy: $final_entropy" >> $ENTROPY_LOG_FILE
    done
}

echo "Starting RNG stress test with $PARALLEL_PROCESSES parallel processes..."

# Start multiple parallel processes to test cryptographic reliability under low entropy
for _ in $(seq 1 $PARALLEL_PROCESSES); do
    test_crypto_operations &
done

# Wait for all background processes to finish
wait

echo "Test complete. Check $ERROR_LOG_FILE for cryptographic errors, $KEY_LOG_FILE for generated keys, $ENTROPY_LOG_FILE for entropy levels, and $WAIT_LOG_FILE for wait times."
