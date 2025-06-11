#!/bin/bash

# Color definitions for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Input file path
INPUT_FILE="InputPrompt.md"

# Function to check if file exists
check_file() {
    if [ ! -f "$INPUT_FILE" ]; then
        echo -e "${RED}Error: $INPUT_FILE not found${NC}"
        exit 1
    fi
}

# Function to analyze markdown structure
analyze_structure() {
    echo -e "${GREEN}Analyzing $INPUT_FILE structure...${NC}"
    
    # Count headers by level
    echo -e "\n${YELLOW}Header Statistics:${NC}"
    echo "Level 1 (#): $(grep -c '^#[^#]' "$INPUT_FILE")"
    echo "Level 2 (##): $(grep -c '^##[^#]' "$INPUT_FILE")"
    echo "Level 3 (###): $(grep -c '^###[^#]' "$INPUT_FILE")"
    
    # Count code blocks
    echo -e "\n${YELLOW}Code Blocks:${NC}"
    echo "Total: $(grep -c '^```' "$INPUT_FILE")"
    
    # List unique code languages used
    echo -e "\n${YELLOW}Languages Used:${NC}"
    sed -n '/^```/p' "$INPUT_FILE" | grep -v '^```$' | sed 's/^```//' | sort -u
}

# Function to extract code blocks
extract_code() {
    echo -e "\n${YELLOW}Extracting Code Blocks...${NC}"
    awk '/^```/{p=1;next} /^```$/{p=0} p' "$INPUT_FILE"
}

# Main execution
main() {
    check_file
    analyze_structure
    extract_code
}

# Run main function
main

# chmod +x analyze_markdown.sh
# ./analyze_markdown.sh
