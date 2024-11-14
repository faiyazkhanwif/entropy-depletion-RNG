#!/bin/bash

# Parameters
NUM_CALLS=100           # Total calls per process
KEY_SIZE=512              # In bytes
PARALLEL_PROCESSES=10     
WAIT_DURATION=300         # in seconds

# Log files for each key
RANDOM_ERROR_LOG_FILE="random_error_log.txt"
RANDOM_KEY_LOG_FILE="random_key_log.txt"
RANDOM_ENTROPY_LOG_FILE="random_entropy_log.txt"
RANDOM_WAIT_LOG_FILE="random_wait_log.txt"

URANDOM_ERROR_LOG_FILE="urandom_error_log.txt"
URANDOM_KEY_LOG_FILE="urandom_key_log.txt"
URANDOM_ENTROPY_LOG_FILE="urandom_entropy_log.txt"
URANDOM_WAIT_LOG_FILE="urandom_wait_log.txt"

RSA_ERROR_LOG_FILE="rsa_error_log.txt"
RSA_KEY_LOG_FILE="rsa_key_log.txt"
RSA_ENTROPY_LOG_FILE="rsa_entropy_log.txt"
RSA_WAIT_LOG_FILE="rsa_wait_log.txt"

EXECUTION_LOG_FILE="execution_time_log.txt"

# Clear existing log files
> $RANDOM_ERROR_LOG_FILE
> $RANDOM_KEY_LOG_FILE
> $RANDOM_ENTROPY_LOG_FILE
> $RANDOM_WAIT_LOG_FILE
> $URANDOM_ERROR_LOG_FILE
> $URANDOM_KEY_LOG_FILE
> $URANDOM_ENTROPY_LOG_FILE
> $URANDOM_WAIT_LOG_FILE
> $RSA_ERROR_LOG_FILE
> $RSA_KEY_LOG_FILE
> $RSA_ENTROPY_LOG_FILE
> $RSA_WAIT_LOG_FILE
> $EXECUTION_LOG_FILE

# Function to generate keys using /dev/random
generate_random_key() {
    local i start_time end_time duration entropy final_entropy

    for i in $(seq 1 $NUM_CALLS); do
        entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        #echo "Process $$ - Iteration $i - Initial Entropy: $entropy" >> $RANDOM_ENTROPY_LOG_FILE
        echo "$entropy" >> $RANDOM_ENTROPY_LOG_FILE
        
        start_time=$(date +%s%3N)
        key=$(head -c $KEY_SIZE /dev/random | openssl enc -base64 2>> $RANDOM_ERROR_LOG_FILE)
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))

        if [ "$duration" -gt 0 ]; then
            #echo "Process $$ - Iteration $i - Wait Time: ${duration}ms" >> $RANDOM_WAIT_LOG_FILE
            echo "$duration" >> $RANDOM_WAIT_LOG_FILE
        fi

        if [ $? -ne 0 ]; then
            echo "Process $$ - Iteration $i - Error: Cryptographic operation failed due to low entropy" >> $RANDOM_ERROR_LOG_FILE
        fi

        echo "$key" >> $RANDOM_KEY_LOG_FILE
        final_entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        #echo "Process $$ - Iteration $i - Final Entropy: $final_entropy" >> $RANDOM_ENTROPY_LOG_FILE
        echo "$final_entropy" >> $RANDOM_ENTROPY_LOG_FILE
    done
}

# Function to generate keys using /dev/urandom
generate_urandom_key() {
    local i start_time end_time duration entropy final_entropy

    for i in $(seq 1 $NUM_CALLS); do
        entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        #echo "Process $$ - Iteration $i - Initial Entropy: $entropy" >> $URANDOM_ENTROPY_LOG_FILE
        echo "$entropy" >> $URANDOM_ENTROPY_LOG_FILE
        
        start_time=$(date +%s%3N)
        key=$(head -c $KEY_SIZE /dev/urandom | openssl enc -base64 2>> $URANDOM_ERROR_LOG_FILE)
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))

        if [ "$duration" -gt 0 ]; then
            #echo "Process $$ - Iteration $i - Wait Time: ${duration}ms" >> $URANDOM_WAIT_LOG_FILE
            echo "$duration" >> $URANDOM_WAIT_LOG_FILE
        fi

        if [ $? -ne 0 ]; then
            echo "Process $$ - Iteration $i - Error: Cryptographic operation failed" >> $URANDOM_ERROR_LOG_FILE
        fi

        echo "$key" >> $URANDOM_KEY_LOG_FILE
        final_entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        #echo "Process $$ - Iteration $i - Final Entropy: $final_entropy" >> $URANDOM_ENTROPY_LOG_FILE
        echo "$final_entropy" >> $URANDOM_ENTROPY_LOG_FILE
    done
}

# Function to generate RSA keys using OpenSSL
generate_rsa_key() {
    local i start_time end_time duration entropy final_entropy

    for i in $(seq 1 $NUM_CALLS); do
        entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        #echo "Process $$ - Iteration $i - Initial Entropy: $entropy" >> $RSA_ENTROPY_LOG_FILE
        echo "$entropy" >> $RSA_ENTROPY_LOG_FILE
        
        start_time=$(date +%s%3N)
        key=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:$KEY_SIZE 2>> $RSA_ERROR_LOG_FILE)
        end_time=$(date +%s%3N)
        duration=$((end_time - start_time))

        if [ "$duration" -gt 0 ]; then
            #echo "Process $$ - Iteration $i - Wait Time: ${duration}ms" >> $RSA_WAIT_LOG_FILE
            echo "$duration" >> $RSA_WAIT_LOG_FILE
        fi

        if [ $? -ne 0 ]; then
            echo "Process $$ - Iteration $i - Error: RSA key generation failed" >> $RSA_ERROR_LOG_FILE
        fi

        echo "$key" >> $RSA_KEY_LOG_FILE
        final_entropy=$(cat /proc/sys/kernel/random/entropy_avail)
        #echo "Process $$ - Iteration $i - Final Entropy: $final_entropy" >> $RSA_ENTROPY_LOG_FILE
        echo "$final_entropy" >> $RSA_ENTROPY_LOG_FILE
    done
}

# Function to execute a key generation method in parallel processes and log execution time
execute_with_timing() {
    local start_time end_time

    echo "Starting execution: $1 with $PARALLEL_PROCESSES parallel processes"
    start_time=$(date +%s)

    for _ in $(seq 1 $PARALLEL_PROCESSES); do
        $1 &  # Run each process in the background
    done

    wait  # Wait for all parallel processes to finish
    end_time=$(date +%s)
    execution_duration=$((end_time - start_time))

    echo "$1 - Execution Time: ${execution_duration}s" >> $EXECUTION_LOG_FILE
}

# Execute each function with 5 minutes wait in between
execute_with_timing generate_random_key
sleep $WAIT_DURATION
execute_with_timing generate_urandom_key
sleep $WAIT_DURATION
execute_with_timing generate_rsa_key

echo "Test complete. Check the respective log files for each key generation method."
