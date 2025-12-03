#!/bin/bash

# Script to load .env file and generate GoogleMapsAPIKey.xcconfig
# This script reads the .env file and creates an xcconfig file for iOS

ENV_FILE="../../.env"
XCCONFIG_FILE="Flutter/GoogleMapsAPIKey.xcconfig"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Warning: .env file not found at $ENV_FILE"
    exit 0
fi

# Read GOOGLE_MAPS_API_KEY from .env
GOOGLE_MAPS_API_KEY=$(grep "GOOGLE_MAPS_API_KEY" "$ENV_FILE" | cut -d '=' -f2 | tr -d ' ')

if [ -z "$GOOGLE_MAPS_API_KEY" ]; then
    echo "Warning: GOOGLE_MAPS_API_KEY not found in .env file"
    exit 0
fi

# Create xcconfig file
mkdir -p Flutter
echo "// Auto-generated from .env file - DO NOT EDIT MANUALLY" > "$XCCONFIG_FILE"
echo "GOOGLE_MAPS_API_KEY=$GOOGLE_MAPS_API_KEY" >> "$XCCONFIG_FILE"

echo "Successfully loaded Google Maps API Key from .env"

