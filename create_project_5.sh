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

# Function: Check system requirements
check_requirements() {
    echo "Checking system requirements..."
    
    # Check and install required packages
    sudo apt-get update
    sudo apt-get install -y llvm lldb
    
    # Update Rust toolchain
    rustup update stable
    rustup component add llvm-tools-preview
    
    # Install cargo tools
    cargo install cargo-llvm-cov --force
    cargo install cargo-binutils --force
    
    # Install VS Code extensions
    code --install-extension ryanluker.vscode-coverage-gutters
    code --install-extension rust-lang.rust-analyzer
}

# Function: Setup project structure
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
    mkdir -p src/{bin,tests}
}

# Function: Create source files
create_source_files() {
    # Create error.rs first
    cat > src/error.rs << 'EOL'
use thiserror::Error;

#[derive(Error, Debug)]
pub enum UppercaseError {
    #[error("Input string cannot be empty")]
    EmptyInput,
}
EOL

    # Create lib.rs
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

    # Create main.rs
    cat > src/bin/main.rs << 'EOL'
use clap::{Command, Arg};
use std::process;
use uppercase_converter::Converter;

fn main() {
    let matches = Command::new("Uppercase Converter")
        .version("1.0")
        .about("Converts input strings to uppercase")
        .arg(
            Arg::new("input")
                .help("The string to convert to uppercase")
                .required(true)
                .index(1),
        )
        .get_matches();

    let input = matches.get_one::<String>("input").unwrap();
    let converter = Converter::new();
    
    match converter.convert_to_uppercase(input) {
        Ok(result) => println!("{}", result),
        Err(e) => {
            eprintln!("Error: {}", e);
            process::exit(1);
        }
    }
}
EOL
}

# Function: Configure VS Code and project settings
configure_project() {
    # Create VS Code settings
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

    # Update Cargo.toml with profiling settings
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

    # Initialize git repository
    git init
    echo "target/" > .gitignore
    git add .
    git commit -m "Initial commit"
}

# Function: Generate profiling data and reports
generate_profiling() {
    # Setup profiling environment
    export RUSTFLAGS="-C instrument-coverage -C link-dead-code"
    
    # Clean and create profiling directory
    rm -rf target/debug/profiling
    mkdir -p target/debug/profiling
    
    # Run tests with profiling
    LLVM_PROFILE_FILE="target/debug/profiling/coverage-%p-%m.profraw" cargo test
    
    # Generate reports
    llvm-profdata merge -sparse target/debug/profiling/*.profraw -o target/debug/profiling/merged.profdata
    
    # Create HTML and text reports
    llvm-cov show \
        --format=html \
        --ignore-filename-regex='/.cargo/registry' \
        --instr-profile=target/debug/profiling/merged.profdata \
        --object target/debug/deps/uppercase_converter-* \
        --output-dir=target/debug/profiling/html
    
    llvm-cov report \
        --use-color \
        --ignore-filename-regex='/.cargo/registry' \
        --instr-profile=target/debug/profiling/merged.profdata \
        --object target/debug/deps/uppercase_converter-* \
        > target/debug/profiling/coverage_report.txt
}

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

<<Block_comment
create_project_file_name=create_project_5.sh
echo $create_project_file_name
chmod +x $create_project_file_name
./$create_project_file_name
Block_comment