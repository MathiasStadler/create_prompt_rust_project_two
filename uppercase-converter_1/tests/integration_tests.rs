#[cfg(test)]
mod integration_tests {
    use assert_cmd::Command;

    #[test]
    fn test_uppercase_conversion() {
        let mut cmd = Command::cargo_bin("uppercase-converter").unwrap();
        cmd.arg("hello").assert().stdout("HELLO\n").success();
    }

    #[test]
    fn test_empty_input() {
        let mut cmd = Command::cargo_bin("uppercase-converter").unwrap();
        cmd.arg("").assert().stdout("\n").success();
    }

    #[test]
    fn test_numeric_input() {
        let mut cmd = Command::cargo_bin("uppercase-converter").unwrap();
        cmd.arg("123").assert().stdout("123\n").success();
    }

    #[test]
    fn test_special_characters() {
        let mut cmd = Command::cargo_bin("uppercase-converter").unwrap();
        cmd.arg("!@#").assert().stdout("!@#\n").success();
    }
}