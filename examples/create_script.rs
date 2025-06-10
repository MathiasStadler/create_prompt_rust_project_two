use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};
use std::collections::HashMap;

/// Main function to set up the project
fn main() -> std::io::Result<()> {
    // Get home directory
    let home = std::env::var("HOME").expect("Could not find HOME directory");
    let project_path = format!("{}/uppercase-converter", home);

    // Remove existing project if it exists
    if Path::new(&project_path).exists() {
        fs::remove_dir_all(&project_path)?;
    }

    // Create project using cargo
    Command::new("cargo")
        .args(&["new", &project_path])
        .status()?;

    // Create project structure
    create_project_structure(&project_path)?;
    
    // Create project files
    create_cargo_toml(&project_path)?;
    create_main_rs(&project_path)?;
    create_lib_rs(&project_path)?;
    create_error_rs(&project_path)?;
    create_documentation(&project_path)?;

    // Build and test project
    Command::new("cargo")
        .current_dir(&project_path)
        .args(&["build"])
        .status()?;

    Command::new("cargo")
        .current_dir(&project_path)
        .args(&["test"])
        .status()?;

    println!("Project setup complete at: {}", project_path);
    Ok(())
}

fn create_project_structure(project_path: &str) -> std::io::Result<()> {
    fs::create_dir_all(format!("{}/src/utils", project_path))?;
    fs::create_dir_all(format!("{}/tests", project_path))?;
    fs::create_dir_all(format!("{}/docs", project_path))?;
    Ok(())
}

fn create_cargo_toml(project_path: &str) -> std::io::Result<()> {
    let cargo_toml = r#"[package]
name = "uppercase-converter"
version = "0.1.0"
edition = "2021"

[dependencies]
clap = { version = "4.4", features = ["derive"] }
thiserror = "1.0"
anyhow = "1.0"

[dev-dependencies]
assert_cmd = "2.0"
predicates = "3.0""#;

    fs::write(format!("{}/Cargo.toml", project_path), cargo_toml)?;
    Ok(())
}

fn create_main_rs(project_path: &str) -> std::io::Result<()> {
    let main_rs = r#"use clap::{Command, Arg};
use std::process;

mod lib;
mod error;

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
    
    match lib::convert_to_uppercase(input) {
        Ok(result) => println!("{}", result),
        Err(e) => {
            eprintln!("Error: {}", e);
            process::exit(1);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_cli() {
        let cmd = Command::new("Uppercase Converter")
            .arg(Arg::new("input").required(true).index(1));
        assert!(cmd.try_get_matches_from(vec!["prog", "test"]).is_ok());
    }
}"#;

    fs::write(format!("{}/src/main.rs", project_path), main_rs)?;
    Ok(())
}

fn create_lib_rs(project_path: &str) -> std::io::Result<()> {
    let lib_rs = r#"use crate::error::UppercaseError;

/// Converts input string to uppercase
pub fn convert_to_uppercase(input: &str) -> Result<String, UppercaseError> {
    if input.is_empty() {
        return Err(UppercaseError::EmptyInput);
    }
    Ok(input.to_uppercase())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_convert_to_uppercase() {
        assert_eq!(convert_to_uppercase("hello").unwrap(), "HELLO");
    }

    #[test]
    fn test_empty_input() {
        assert!(convert_to_uppercase("").is_err());
    }
}"#;

    fs::write(format!("{}/src/lib.rs", project_path), lib_rs)?;
    Ok(())
}

fn create_error_rs(project_path: &str) -> std::io::Result<()> {
    let error_rs = r#"use thiserror::Error;

#[derive(Error, Debug)]
pub enum UppercaseError {
    #[error("Input string cannot be empty")]
    EmptyInput,
}"#;

    fs::write(format!("{}/src/error.rs", project_path), error_rs)?;
    Ok(())
}

fn create_documentation(project_path: &str) -> std::io::Result<()> {
    // Create project_path.md
    let system_info = collect_system_info();
    let project_path_md = format!(
        r#"# Project Information
- Name: uppercase-converter
- Start Date: {}
- Operating System: {}
- Hardware: {}
- Rust Version: {}"#,
        system_info.get("date").unwrap_or(&String::from("Unknown")),
        system_info.get("os").unwrap_or(&String::from("Unknown")),
        system_info.get("hardware").unwrap_or(&String::from("Unknown")),
        system_info.get("rust_version").unwrap_or(&String::from("Unknown"))
    );

    fs::write(format!("{}/docs/project_path.md", project_path), project_path_md)?;

    // Create changelog.md
    let changelog = r#"# Changelog
## [0.1.0] - Initial Release
- Basic uppercase conversion functionality
- Command-line interface
- Error handling"#;

    fs::write(format!("{}/docs/changelog.md", project_path), changelog)?;
    Ok(())
}

fn collect_system_info() -> HashMap<String, String> {
    let mut info = HashMap::new();
    
    // Get current date
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    info.insert("date".to_string(), format!("{}", now));

    // Get OS info
    if let Ok(output) = Command::new("uname").arg("-s").output() {
        if let Ok(os) = String::from_utf8(output.stdout) {
            info.insert("os".to_string(), os.trim().to_string());
        }
    }

    // Get Rust version
    if let Ok(output) = Command::new("rustc").arg("--version").output() {
        if let Ok(version) = String::from_utf8(output.stdout) {
            info.insert("rust_version".to_string(), version.trim().to_string());
        }
    }

    // Get hardware info
    if let Ok(output) = Command::new("uname").arg("-m").output() {
        if let Ok(hardware) = String::from_utf8(output.stdout) {
            info.insert("hardware".to_string(), hardware.trim().to_string());
        }
    }

    info
}