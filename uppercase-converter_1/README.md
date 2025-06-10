# Uppercase Converter

This project is a command-line application written in Rust that converts input strings to uppercase. It utilizes the `clap` library for command-line argument parsing and implements error handling with `anyhow` and `thiserror`.

## Core Functionality

- Accepts string input from users via the command line.
- Converts the input string to uppercase.
- Displays the converted string as output.

## Project Structure

```
uppercase-converter
├── src
│   ├── lib.rs          # Main library code for the uppercase converter
│   ├── main.rs         # Entry point of the command-line application
│   ├── error.rs        # Custom error types and handling logic
│   └── utils
│       └── mod.rs      # Utility functions for the application
├── tests
│   ├── cli_tests.rs    # Unit tests for the command-line interface
│   └── integration_tests.rs # Integration tests for overall functionality
├── docs
│   ├── project_path.md  # Project documentation
│   └── changelog.md     # Log of changes made to the project
├── examples
│   └── demo.rs          # Demonstration of how to use the uppercase converter
├── Cargo.toml           # Project configuration file
└── Cargo.lock           # Dependency lock file
```

## Installation

To install the necessary dependencies, run the following command:

```bash
cargo build
```

## Usage

To use the uppercase converter, run the following command in your terminal:

```bash
cargo run -- <your-string>
```

Replace `<your-string>` with the string you want to convert to uppercase.

## Testing

To run the tests for the application, use the following command:

```bash
cargo test
```

## License

This project is licensed under the MIT License. See the LICENSE file for more details
