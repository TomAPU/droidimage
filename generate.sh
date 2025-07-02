#!/bin/bash

# Exit on error
set -e

# Check that an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <output-directory>"
    exit 1
fi

# Validate TARGETARCH if set
if [ -n "$TARGETARCH" ]; then
    if [ "$TARGETARCH" != "amd64" ] && [ "$TARGETARCH" != "arm64" ]; then
        echo "Error: TARGETARCH must be 'amd64', 'arm64' or unset."
        exit 1
    fi
    echo "TARGETARCH is set to: $TARGETARCH"
else
    echo "TARGETARCH is not set, proceeding without it."
fi

ENV_VARS=""
if [ -n "$TARGETARCH" ]; then
    ENV_VARS="-e TARGETARCH=$TARGETARCH"
fi

# Resolve the output directory and check existence
OUTPUT_DIR=$(realpath "$1")

if [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Directory '$OUTPUT_DIR' does not exist."
    exit 1
fi

# Optional: Print the mapped directory for clarity
echo "Using host directory: $OUTPUT_DIR"
echo "Mounting as /output inside the container."

# Build the Docker image
docker build -t buildroot-builder .

# Run the container with the output directory mounted
docker run -it -v "$OUTPUT_DIR:/output" $ENV_VARS buildroot-builder
