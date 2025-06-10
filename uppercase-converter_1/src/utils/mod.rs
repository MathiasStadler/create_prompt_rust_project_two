// src/utils/mod.rs

/// Utility functions for the uppercase converter application.

/// Validates the input string to ensure it is not empty.
pub fn validate_input(input: &str) -> Result<(), String> {
    if input.trim().is_empty() {
        Err("Input cannot be empty.".to_string())
    } else {
        Ok(())
    }
}

/// Converts a given string to uppercase.
pub fn to_uppercase(input: &str) -> String {
    input.to_uppercase()
}