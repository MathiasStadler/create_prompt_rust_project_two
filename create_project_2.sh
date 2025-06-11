#!/bin/bash

# Enable error handling and debugging
set -e
set -x

# Setup logging
LOG_DIR="logs"
LOG_FILE="${LOG_DIR}/project_setup_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "$LOG_DIR"
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project configuration
HOME_DIR="$HOME"
PROJECT_NAME="uppercase-converter"
PROJECT_PATH="$HOME_DIR/$PROJECT_NAME"

# Function: Check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check Rust installation and update
    rustup update stable
    rustc --version
    
    # Check required tools
    local required_tools=(cargo rustc git code)
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Missing required tools: ${missing_tools[*]}${NC}"
        exit 1
    fi

    # Install/Update cargo tools
    cargo install cargo-llvm-cov --force
    cargo install cargo-audit --force
    
    # Install VS Code extensions
    code --install-extension ryanluker.vscode-coverage-gutters
    code --install-extension rust-lang.rust-analyzer
}

# Function: Setup project structure
setup_project() {
    echo "Setting up project structure..."
    
    # Remove existing project if present
    if [ -d "$PROJECT_PATH" ]; then
        read -p "Project exists. Remove it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_PATH"
        else
            exit 1
        fi
    fi

    # Create new project
    cargo new "$PROJECT_PATH" --lib
    cd "$PROJECT_PATH"
    
    # Add dependencies using cargo
    cargo add clap --features derive
    cargo add thiserror
    cargo add anyhow
    cargo add --dev assert_cmd
    cargo add --dev predicates
    
    # Create directory structure
    mkdir -p src/{bin,tests} docs
}

# Function: Configure project
configure_project() {
    echo "Configuring project..."
    
    # Create VS Code settings
    mkdir -p .vscode
    cat > .vscode/settings.json << 'EOL'
{
    "rust-analyzer.checkOnSave.command": "clippy",
    "coverage-gutters.lcovname": "lcov.info",
    "coverage-gutters.showLineCoverage": true,
    "coverage-gutters.showRulerCoverage": true,
    "editor.formatOnSave": true
}
EOL

    # Initialize git repository
    git init
    echo "target/" > .gitignore
    git add .
    git commit -m "Initial commit"
}

# Function: Run tests and generate coverage
run_tests_and_coverage() {
    echo "Running tests and generating coverage..."
    
    # Format code
    cargo fmt
    
    # Run tests with coverage
    cargo llvm-cov clean
    cargo llvm-cov --all-features --workspace --lcov --output-path lcov.info
    cargo llvm-cov html
    
    # Check coverage percentage
    local coverage=$(cargo llvm-cov --summarize | grep "line coverage" | awk '{print $4}')
    echo "Coverage: $coverage"
    
    if (( $(echo "$coverage < 100" | bc -l) )); then
        echo -e "${RED}Warning: Coverage below 100% ($coverage%)${NC}"
    else
        echo -e "${GREEN}Full coverage achieved!${NC}"
    fi
}

# Main execution
main() {
    echo "Starting project setup at $(date)"
    
    check_requirements
    setup_project
    configure_project
    run_tests_and_coverage
    
    echo -e "${GREEN}Project setup complete!${NC}"
    echo "Project location: $PROJECT_PATH"
    echo "Coverage report: $PROJECT_PATH/target/llvm-cov/html/index.html"
    echo "Log file: $LOG_FILE"
}

# Run main function
main

# chmod +x create_project.sh
# ./create_project.sh
