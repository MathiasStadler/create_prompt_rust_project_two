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
NC='\033[0m'

# Project configuration
HOME_DIR="$HOME"
PROJECT_NAME="uppercase-converter"
PROJECT_PATH="$HOME_DIR/$PROJECT_NAME"

# Function: Check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check and install required packages
    sudo apt-get update
    sudo apt-get install -y llvm lldb

    # Update Rust and tools
    rustup update stable
    rustup component add llvm-tools-preview
    
    # Install cargo tools
    cargo install cargo-llvm-cov --force
    cargo install cargo-binutils --force
    
    # Check VS Code extensions
    code --install-extension ryanluker.vscode-coverage-gutters
    code --install-extension rust-lang.rust-analyzer
}

# Function: Setup project
setup_project() {
    if [ -d "$PROJECT_PATH" ]; then
        read -p "Project exists. Remove? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_PATH"
        else
            exit 1
        fi
    fi

    # Create project
    cargo new "$PROJECT_PATH" --lib
    cd "$PROJECT_PATH"
    
    # Add dependencies
    cargo add clap --features derive
    cargo add thiserror
    cargo add anyhow
    cargo add --dev assert_cmd
    cargo add --dev predicates
}

# Function: Configure project
configure_project() {
    # Setup VS Code configuration
    mkdir -p .vscode
    cat > .vscode/settings.json << 'EOL'
{
    "rust-analyzer.checkOnSave.command": "clippy",
    "coverage-gutters.lcovname": "target/llvm-cov/lcov.info",
    "coverage-gutters.showLineCoverage": true,
    "coverage-gutters.showRulerCoverage": true,
    "editor.formatOnSave": true
}
EOL

    # Add profiling configuration to Cargo.toml
    cat >> Cargo.toml << 'EOL'

[profile.release]
debug = true
debug-assertions = true

[profile.profiling]
inherits = "release"
debug = true
debug-assertions = true
lto = false
incremental = false
EOL
}

# Function: Create source files
create_source_files() {
    # Create source files with full test coverage
    cat > src/lib.rs << 'EOL'
mod error;

use crate::error::UppercaseError;

#[derive(Debug)]
pub struct Converter;

impl Converter {
    pub fn new() -> Self { Self }

    pub fn convert_to_uppercase(&self, input: &str) -> Result<String, UppercaseError> {
        if input.is_empty() {
            return Err(UppercaseError::EmptyInput);
        }
        Ok(input.to_uppercase())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new() {
        let converter = Converter::new();
        assert!(matches!(converter, Converter));
    }

    #[test]
    fn test_convert_to_uppercase() {
        let converter = Converter::new();
        assert_eq!(converter.convert_to_uppercase("hello").unwrap(), "HELLO");
        assert_eq!(converter.convert_to_uppercase("Test123").unwrap(), "TEST123");
    }

    #[test]
    fn test_empty_input() {
        let converter = Converter::new();
        assert!(converter.convert_to_uppercase("").is_err());
    }
}
EOL
}

# Function: Generate profiling data
generate_profiling() {
    echo "Generating profiling data..."
    
    # Set profiling flags
    export RUSTFLAGS="-C instrument-coverage -C link-dead-code"
    
    # Clean previous profiling data
    rm -rf target/debug/profiling
    mkdir -p target/debug/profiling
    
    # Run tests with profiling
    LLVM_PROFILE_FILE="target/debug/profiling/coverage-%p-%m.profraw" cargo test
    
    # Merge profiling data
    llvm-profdata merge -sparse target/debug/profiling/*.profraw -o target/debug/profiling/merged.profdata
    
    # Generate reports
    llvm-cov report \
        --use-color \
        --ignore-filename-regex='/.cargo/registry' \
        --instr-profile=target/debug/profiling/merged.profdata \
        --object target/debug/deps/uppercase_converter-* \
        > target/debug/profiling/coverage_report.txt
    
    # Generate HTML report
    llvm-cov show \
        --format=html \
        --ignore-filename-regex='/.cargo/registry' \
        --instr-profile=target/debug/profiling/merged.profdata \
        --object target/debug/deps/uppercase_converter-* \
        --output-dir=target/debug/profiling/html
}

# Main execution
main() {
    echo "Starting project setup at $(date)"
    
    check_requirements
    setup_project
    configure_project
    create_source_files
    
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

# Run main function
main

# chmod +x create_project_3.sh
# ./create_project_3.sh