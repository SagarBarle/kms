#!/bin/bash

set -e

MASTER_KEY="master.key"
ITER=100000

START_TIME=$(date +%s)

usage() {
  echo "Usage:"
  echo "  $0 encrypt <file>"
  echo "  $0 decrypt <file.enc>"
  exit 1
}

if [ $# -ne 2 ]; then
  usage
fi

MODE=$1
INPUT_FILE=$2

DATA_KEY_FILE="${INPUT_FILE}.key"
ENCRYPTED_DATA_KEY_FILE="${INPUT_FILE%.enc}.key.enc"
    
if [ ! -f "$MASTER_KEY" ]; then
  echo "Generating master key..."
  openssl rand -base64 256 > "$MASTER_KEY"
  chmod 600 "$MASTER_KEY"
fi

if [ "$MODE" == "encrypt" ]; then

  OUTPUT_FILE="${INPUT_FILE}.enc"

  echo "Generating data key..."
  openssl rand -base64 32 > "$DATA_KEY_FILE"
  chmod 600 "$DATA_KEY_FILE"

  echo "Encrypting file..."
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter $ITER \
    -in "$INPUT_FILE" \
    -out "$OUTPUT_FILE" \
    -pass file:"$DATA_KEY_FILE"

  echo "Encrypting data key..."
  openssl enc -aes-256-cbc -salt -pbkdf2 -iter $ITER \
    -in "$DATA_KEY_FILE" \
    -out "$ENCRYPTED_DATA_KEY_FILE" \
    -pass file:"$MASTER_KEY"

  rm -f "$DATA_KEY_FILE"

  echo "Encryption complete"

elif [ "$MODE" == "decrypt" ]; then

  DECRYPTED_FILE="${INPUT_FILE%.enc}"

  echo "Decrypting data key..."
  openssl enc -aes-256-cbc -d -pbkdf2 -iter $ITER \
    -in "$ENCRYPTED_DATA_KEY_FILE" \
    -out "$DATA_KEY_FILE" \
    -pass file:"$MASTER_KEY"

  echo "Decrypting file..."
  openssl enc -aes-256-cbc -d -pbkdf2 -iter $ITER \
    -in "$INPUT_FILE" \
    -out "$DECRYPTED_FILE" \
    -pass file:"$DATA_KEY_FILE"

  rm -f "$DATA_KEY_FILE"

  echo "Decryption complete"

else
  usage
fi

END_TIME=$(date +%s)
ELAPSED_TIME=$((END_TIME - START_TIME))
echo "Time taken: $ELAPSED_TIME seconds"