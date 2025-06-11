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

# ... existing functions: check_requirements, setup_project, create_source_files, etc ...

# Main execution
main() {
    echo "Starting project setup at $(date)"
    
    check_requirements || exit 1
    setup_project || exit 1
    create_source_files || exit 1
    configure_project || exit 1
    
    # Run tests and generate reports
    cargo fmt
    cargo clippy
    cargo test
    cargo llvm-cov --html --output-dir target/llvm-cov/html
    cargo llvm-cov --lcov --output-path target/llvm-cov/lcov.info
    generate_profiling
    
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

# Add start instructions as block command
: <<'START_INSTRUCTIONS'
To use this script:

1. Save this file as create_project_final.sh
2. Make it executable:
   chmod +x create_project_final.sh
3. Run the script:
   ./create_project_final.sh

The script will:
- Create a new Rust project
- Set up all required dependencies
- Configure VS Code settings
- Generate coverage reports
- Create profiling data
- Log all operations

Reports will be available at:
- Coverage HTML: ~/uppercase-converter/target/llvm-cov/html/index.html
- Coverage LCOV: ~/uppercase-converter/target/llvm-cov/lcov.info
- Profiling HTML: ~/uppercase-converter/target/debug/profiling/html/index.html
- Setup Log: logs/project_setup_*.log

Requirements:
- Linux/Unix system
- Rust toolchain installed
- VS Code with required extensions
- Git installed
- LLVM tools installed

For manual execution:
create_project_file_name=create_project_final.sh
echo $create_project_file_name
chmod +x $create_project_file_name
./$create_project_file_name
START_INSTRUCTIONS