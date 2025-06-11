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
    if command -v apt-get &> /dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq llvm lldb
    fi
    
    # Update Rust toolchain
    rustup update stable || {
        echo -e "${RED}Failed to update Rust toolchain${NC}"
        return 1
    }
    rustup component add llvm-tools-preview
    
    # Install cargo tools
    cargo install cargo-llvm-cov --quiet || true
    cargo install cargo-binutils --quiet || true
    
    # Check VS Code installation
    if ! command -v code &> /dev/null; then
        echo -e "${RED}VS Code not installed${NC}"
        return 1
    fi
    
    # Install VS Code extensions
    code --install-extension ryanluker.vscode-coverage-gutters || true
    code --install-extension rust-lang.rust-analyzer || true
}

# Function: Setup project structure
setup_project() {
    if [ -d "$PROJECT_PATH" ]; then
        echo -e "${YELLOW}Project directory exists at: $PROJECT_PATH${NC}"
        read -p "Remove it? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_PATH"
        else
            return 1
        fi
    fi

    # Create new project
    cargo new "$PROJECT_PATH" --lib || {
        echo -e "${RED}Failed to create project${NC}"
        return 1
    }
    cd "$PROJECT_PATH"
    
    # Add dependencies
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

# Function: Configure project
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

    # Initialize git repository
    git init
    echo "/target/" > .gitignore
    echo "Cargo.lock" >> .gitignore
    git add .
    git commit -m "Initial commit"
}

# Function: Generate profiling data
generate_profiling() {
    # Set profiling flags
    export RUSTFLAGS="-C instrument-coverage"
    
    # Clean and create profiling directory
    rm -rf target/debug/profiling
    mkdir -p target/debug/profiling
    
    # Run tests with profiling
    LLVM_PROFILE_FILE="target/debug/profiling/coverage-%p-%m.profraw" cargo test
    
    # Generate reports
    if [ -d target/debug/deps ]; then
        llvm-profdata merge -sparse target/debug/profiling/*.profraw -o target/debug/profiling/merged.profdata
        
        # Find the test binary
        TEST_BIN=$(find target/debug/deps -type f -executable -name "uppercase_converter-*" | head -n 1)
        
        if [ -n "$TEST_BIN" ]; then
            llvm-cov show \
                --format=html \
                --ignore-filename-regex='/.cargo/registry' \
                --instr-profile=target/debug/profiling/merged.profdata \
                --object "$TEST_BIN" \
                --output-dir=target/debug/profiling/html
                
            llvm-cov report \
                --ignore-filename-regex='/.cargo/registry' \
                --instr-profile=target/debug/profiling/merged.profdata \
                --object "$TEST_BIN" \
                > target/debug/profiling/coverage_report.txt
        else
            echo -e "${RED}No test binary found${NC}"
            return 1
        fi
    else
        echo -e "${RED}No debug artifacts found${NC}"
        return 1
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
create_project_file_name=create_project_7.sh
echo $create_project_file_name
chmod +x $create_project_file_name
./$create_project_file_name
Block_comment