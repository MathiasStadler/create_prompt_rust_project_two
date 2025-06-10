// src/lib.rs

use crate::error::UppercaseError;

/// Converts the input string to uppercase
///
/// # Arguments
/// * `input` - The string to convert
///
/// # Returns
/// * `Result<String, UppercaseError>` - The uppercase string or an error
pub fn convert_to_uppercase(input: &str) -> Result<String, UppercaseError> {
    if input.is_empty() {
        return Err(UppercaseError::EmptyInput);
    }
    Ok(input.to_uppercase())
}