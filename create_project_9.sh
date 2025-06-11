#!/bin/bash

# ... existing code until generate_profiling function ...

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