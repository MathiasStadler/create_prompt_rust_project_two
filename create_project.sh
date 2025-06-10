#!/bin/bash

# Exit on error and enable debugging
set -e
set -x

# Color definitions for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Setup project paths
HOME_DIR="$HOME"
PROJECT_NAME="uppercase-converter"
PROJECT_PATH="$HOME_DIR/$PROJECT_NAME"

# Function to check for required tools
check_requirements() {
    local missing_tools=()
    
    # Check for required commands
    for cmd in cargo rustc git; do
        if ! command -v $cmd &> /dev/null; then
            missing_tools+=($cmd)
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        exit 1
    fi
}

# Function to safely handle existing project directory
handle_existing_project() {
    if [ -d "$PROJECT_PATH" ]; then
        echo -e "${YELLOW}Warning: Project directory already exists at: $PROJECT_PATH${NC}"
        read -p "Do you want to remove it and continue? (y/n) " -n 1 -r
        echo    # Move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Removing existing project directory...${NC}"
            rm -rf "$PROJECT_PATH"
            return 0
        else
            echo -e "${RED}Aborting script...${NC}"
            exit 1
        fi
    fi
}

# Main setup function
main() {
    echo -e "${GREEN}Starting project setup...${NC}"
    
    # Check requirements first
    check_requirements
    
    # Handle existing project
    handle_existing_project
    
    echo -e "${GREEN}Setting up project in: $PROJECT_PATH${NC}"

    # Create new project
    cargo new "$PROJECT_PATH"
    cd "$PROJECT_PATH"

    # Create project structure
    mkdir -p src/{utils,tests} docs

    # Write Cargo.toml
    cat > Cargo.toml << 'EOL'
[package]
name = "uppercase-converter"
version = "0.1.0"
edition = "2021"
authors = ["Your Name <your.email@example.com>"]
description = "A command-line tool to convert strings to uppercase"

[dependencies]
clap = { version = "4.4", features = ["derive"] }
thiserror = "1.0"
anyhow = "1.0"

[dev-dependencies]
assert_cmd = "2.0"
predicates = "3.0"
EOL

    # Write lib.rs
    cat > src/lib.rs << 'EOL'
mod error;

use crate::error::UppercaseError;

#[derive(Debug)]
pub struct Converter;

impl Converter {
    pub fn new() -> Self {
        Converter
    }

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
    fn test_convert_to_uppercase() {
        let converter = Converter::new();
        assert_eq!(converter.convert_to_uppercase("hello").unwrap(), "HELLO");
    }

    #[test]
    fn test_empty_input() {
        let converter = Converter::new();
        assert!(converter.convert_to_uppercase("").is_err());
    }
}
EOL

    # Write main.rs
    cat > src/main.rs << 'EOL'
use clap::{Command, Arg};
use std::process;
use uppercase_converter::Converter;

fn main() {
    let matches = Command::new("Uppercase Converter")
        .version("1.0")
        .author("Your Name <your.email@example.com>")
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

    # Write error.rs
    cat > src/error.rs << 'EOL'
use thiserror::Error;

#[derive(Error, Debug)]
pub enum UppercaseError {
    #[error("Input string cannot be empty")]
    EmptyInput,
}
EOL

    # Create README
    cat > README.md << "EOL"
# Uppercase Converter

A command-line tool to convert strings to uppercase.

## Usage
\`\`\`bash
cargo run -- "your text here"
\`\`\`

## Features
- Converts text to uppercase
- Command-line interface
- Error handling
EOL

    # Initialize git repository
    git init
    git add .
    git commit -m "Initial commit"

    # Format and test
    cargo fmt
    cargo build
    cargo test

    echo -e "${GREEN}Project setup complete!${NC}"
    echo -e "${GREEN}Try: cargo run -- \"hello world\"${NC}"
}

# Run the main function
main