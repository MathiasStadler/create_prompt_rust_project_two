#!/bin/bash

# Enable error handling and debugging
set -e
set -x

# Setup logging with timestamps
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/project_setup_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

# Color definitions for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Project configuration
HOME_DIR="$HOME"
PROJECT_NAME="uppercase-converter"
PROJECT_PATH="$HOME_DIR/$PROJECT_NAME"

# Function: Generate profiling data
generate_profiling() {
    echo "Generating profiling data..."
    
    # Set profiling flags
    export RUSTFLAGS="-C instrument-coverage -C link-dead-code"
    
    # Clean and create profiling directory
    rm -rf target/debug/profiling
    mkdir -p target/debug/profiling
    
    # Run tests with profiling
    LLVM_PROFILE_FILE="target/debug/profiling/coverage-%p-%m.profraw" cargo test
    
    # Wait for file system
    sleep 2
    
    # Check for profile data
    if ! compgen -G "target/debug/profiling/*.profraw" > /dev/null; then
        echo -e "${RED}No profile data generated${NC}"
        return 1
    fi
    
    # Merge profile data
    llvm-profdata merge \
        -sparse target/debug/profiling/*.profraw \
        -o target/debug/profiling/merged.profdata || {
        echo -e "${RED}Failed to merge profile data${NC}"
        return 1
    }
    
    # Find the correct test binary
    TEST_BIN=$(find target/debug/deps \
        -type f -executable \
        -name "uppercase_converter-*" \
        ! -name "*.d" \
        -print0 | xargs -0 ls -t | head -n1)
    
    if [ ! -f "$TEST_BIN" ]; then
        echo -e "${RED}Test binary not found${NC}"
        return 1
    fi
    
    echo "Using test binary: $TEST_BIN"
    
    # Generate HTML report
    mkdir -p target/debug/profiling/html
    llvm-cov show \
        --use-color \
        --ignore-filename-regex='/.cargo/registry' \
        --format=html \
        --instr-profile=target/debug/profiling/merged.profdata \
        --object "$TEST_BIN" \
        --output-dir=target/debug/profiling/html \
        --show-instantiations \
        --show-line-counts-or-regions || {
        echo -e "${RED}Failed to generate HTML report${NC}"
        return 1
    }
    
    # Generate text report
    llvm-cov report \
        --use-color \
        --ignore-filename-regex='/.cargo/registry' \
        --instr-profile=target/debug/profiling/merged.profdata \
        --object "$TEST_BIN" \
        --show-branch-summary \
        > target/debug/profiling/coverage_report.txt || {
        echo -e "${RED}Failed to generate text report${NC}"
        return 1
    }
    
    echo -e "${GREEN}Profiling reports generated successfully${NC}"
}

# ... rest of your script with open_reports, main function, and START_INSTRUCTIONS ...
# Function to open reports in browser
open_reports() {
    echo "Opening reports in browser..."
    
    local COVERAGE_HTML="$PROJECT_PATH/target/llvm-cov/html/index.html"
    local PROFILING_HTML="$PROJECT_PATH/target/debug/profiling/html/index.html"
    
    if [ -f "$COVERAGE_HTML" ]; then
        xdg-open "$COVERAGE_HTML"
        echo -e "${GREEN}Coverage report opened${NC}"
    else
        echo -e "${RED}Coverage report not found${NC}"
    fi
    
    if [ -f "$PROFILING_HTML" ]; then
        xdg-open "$PROFILING_HTML"
        echo -e "${GREEN}Profiling report opened${NC}"
    else
        echo -e "${RED}Profiling report not found${NC}"
    fi
}

# Main execution
main() {
    echo "Starting project setup at $(date)"
    
    check_requirements || exit 1
    setup_project || exit 1
    create_source_files || exit 1
    configure_project || exit 1
    
    # Run tests and generate reports
    cargo fmt || true
    cargo clippy
    cargo test
    cargo llvm-cov --html --output-dir target/llvm-cov/html
    cargo llvm-cov --lcov --output-path target/llvm-cov/lcov.info
    generate_profiling || echo -e "${YELLOW}Profiling failed but continuing...${NC}"
    open_reports
    
    echo -e "${GREEN}Project setup complete!${NC}"
    echo "Project location: $PROJECT_PATH"
    echo "Coverage report: $PROJECT_PATH/target/llvm-cov/html/index.html"
    echo "Profiling report: $PROJECT_PATH/target/debug/profiling/html/index.html"
    echo "Log file: $LOG_FILE"
}

# Run main function with error handling
main || {
    echo -e "${RED}Script failed! Check the log file: $LOG_FILE${NC}"
    exit 1
}

: <<'START_INSTRUCTIONS'
To use this script:

1. Save this script:
   vim create_project_final.sh

2. Make it executable:
   chmod +x create_project_final.sh

3. Run the script:
   ./create_project_final.sh

The script will:
- Create a new Rust project
- Set up all required dependencies
- Configure VS Code settings
- Generate and open coverage reports
- Create and open profiling data
- Log all operations

Reports will automatically open in your browser at:
- Coverage HTML: ~/uppercase-converter/target/llvm-cov/html/index.html
- Coverage LCOV: ~/uppercase-converter/target/llvm-cov/lcov.info
- Profiling HTML: ~/uppercase-converter/target/debug/profiling/html/index.html
- Setup Log: logs/project_setup_*.log

Requirements:
- Linux/Unix system
- Rust toolchain installed
- VS Code with extensions:
  - Coverage Gutters
  - rust-analyzer
- Git installed
- LLVM tools installed

Quick start:
create_project_file_name=create_project_final.sh
echo $create_project_file_name
chmod +x $create_project_file_name
./$create_project_file_name
START_INSTRUCTIONS