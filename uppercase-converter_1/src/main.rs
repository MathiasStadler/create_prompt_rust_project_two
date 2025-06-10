use clap::{Command, Arg};
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
        Ok(result) => {
            println!("{}", result);
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            process::exit(1);
        }
    }
}