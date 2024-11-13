#!/bin/bash

# Parameters
NUM_CALLS=10000           # Total calls per process
KEY_SIZE=256              # Key size in bytes for secure cryptographic operations (256 FOR RSA)
PARALLEL_PROCESSES=10     # Number of parallel processes
ERROR_LOG_FILE="error_log.txt"
KEY_LOG_FILE="key_log.txt"
ENTROPY_LOG_FILE="entropy_log.txt"
RSA_KEY_LOG_FILE="rsa_key_log.txt"
> $ERROR_LOG_FILE
> $KEY_LOG_FILE
> $ENTROPY_LOG_FILE
> $RSA_KEY_LOG_FILE

# Script Contains Manual Waiting -> This is unnecessary as dev/random will auto block the operation if the entropy is not enough. 
# Function to test cryptographic operations and log potential issues
test_crypto_operations() {
    for i in $(seq 1 $NUM_CALLS); do
        # Continuously check entropy before each operation
        entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        
        # Log the current entropy level before each operation
        echo "Process $$ - Iteration $i - Entropy: $entropy" >> $ENTROPY_LOG_FILE

        # If entropy is zero, log and wait until it's non-zero -> Manual Waiting
        while [ "$entropy" -eq 0 ]; do
            echo "Process $$ - Iteration $i - Waiting for entropy to replenish" >> $ERROR_LOG_FILE
            entropy=$(cat /proc/sys/kernel/random/entropy_avail)
            sleep 0.01
        done

        # Generate a secure key using /dev/random to enforce strict reliance on system entropy
        key=$(head -c $KEY_SIZE /dev/random | openssl enc -base64 2>> $ERROR_LOG_FILE)

        # Generate a secure key using OpenSSL, capturing any errors -- use this to generate using openssl -> no strict enforcement on system entropy
        #key=$(openssl rand -hex $KEY_SIZE 2>> $ERROR_LOG_FILE)

        # If fails, log an error message
        if [ $? -ne 0 ]; then
            echo "Process $$ - Iteration $i - Error: Cryptographic operation failed due to low entropy" >> $ERROR_LOG_FILE
        fi

        # Log each generated key
        echo "$key" >> $KEY_LOG_FILE

        # Perform RSA key generation - use this to generate using openssl genpkey (Default) -> rsa_key_bits:2048 -> no strict enforcement on system entropy
        #rsa_key=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out /dev/null 2>> $ERROR_LOG_FILE)
        
        # If RSA generation fails, log an error message
        #if [ $? -ne 0 ]; then
        #    echo "Process $$ - Iteration $i - Error: RSA key generation failed due to low entropy" >> $ERROR_LOG_FILE
        #fi

        # Log a message for each RSA key generation attempt
        #echo "Process $$ - Iteration $i - RSA key generated" >> $RSA_KEY_LOG_FILE
    done
}

echo "Starting enhanced RNG stress test with $PARALLEL_PROCESSES parallel processes..."

# Start multiple parallel processes to test cryptographic reliability under low entropy
for _ in $(seq 1 $PARALLEL_PROCESSES); do
    test_crypto_operations &
done

# Wait for all background processes to finish
wait

echo "Test complete. Check $ERROR_LOG_FILE for cryptographic errors, $KEY_LOG_FILE for generated keys, $ENTROPY_LOG_FILE for entropy levels, and $RSA_KEY_LOG_FILE for RSA generation logs."
