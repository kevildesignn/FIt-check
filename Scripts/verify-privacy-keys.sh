#!/bin/bash

# verify-privacy-keys.sh
# Verifies that required privacy usage descriptions are present in Info.plist
# This script is run during the Xcode build process to ensure the app has
# the necessary privacy keys before building.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the Info.plist path from the project
INFO_PLIST="${INFOPLIST_FILE}"

# If INFOPLIST_FILE is not set (running outside Xcode), use a default path
if [ -z "$INFO_PLIST" ]; then
    INFO_PLIST="FIt Check/Info.plist"
fi

# Make path absolute if it's relative
if [[ ! "$INFO_PLIST" = /* ]]; then
    INFO_PLIST="${SRCROOT}/${INFO_PLIST}"
fi

echo "🔍 Verifying privacy keys in Info.plist..."
echo "   Path: ${INFO_PLIST}"

# Check if Info.plist exists
if [ ! -f "$INFO_PLIST" ]; then
    echo -e "${RED}❌ Error: Info.plist not found at: ${INFO_PLIST}${NC}"
    exit 1
fi

# Define required privacy keys for this app
# Add more keys here as needed
REQUIRED_KEYS=(
    "NSCameraUsageDescription"
)

# Track if any keys are missing
MISSING_KEYS=()

# Check each required key
for KEY in "${REQUIRED_KEYS[@]}"; do
    VALUE=$(/usr/libexec/PlistBuddy -c "Print :${KEY}" "$INFO_PLIST" 2>/dev/null || echo "")
    
    if [ -z "$VALUE" ]; then
        MISSING_KEYS+=("$KEY")
        echo -e "${RED}❌ Missing: ${KEY}${NC}"
    else
        echo -e "${GREEN}✓ Found: ${KEY}${NC}"
        echo "   Value: ${VALUE}"
    fi
done

# Check results
if [ ${#MISSING_KEYS[@]} -eq 0 ]; then
    echo -e "\n${GREEN}✅ All required privacy keys are present!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Build Failed: Missing ${#MISSING_KEYS[@]} required privacy key(s)${NC}"
    echo -e "${YELLOW}Please add the following keys to your Info.plist:${NC}"
    for KEY in "${MISSING_KEYS[@]}"; do
        echo "   - $KEY"
    done
    exit 1
fi
