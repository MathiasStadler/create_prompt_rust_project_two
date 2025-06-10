## old

- Condition
  - Create a new project in the current folder
  - Create a single bash script with all the necessary steps to create the Project
  - Review iterative the hole output of the script and  fix all errors
  - Review iterative all problems of the project and fir it
  - OS: Linux/Unix
  - IDE: Visual Studio Code
  - Language: Rust (latest stable version)
  - Follow Rust standard formatting
  - Coverage Tools: LLVM Coverage, Coverage Gutters extension
  - Check and if note install command for install extension
  - Make every thing inside a rust program files, not used any bash script
  - Create a new project in the current folder
  - The test of the program should cover 100% of the rust code
  - Write for each function , line, region ,blo- All test should covert 100% of the program code and branch a testcase
  - Include comprehensive test cases
  - Implement error handling and it
  - Add documentation comments
  - Generate coverage reports
  - - Create project documentation as markdown with:
    - Project name and creation date (with timezone)
    - Environment details
    - System configuration
    - Build status
    - Test results
    - Coverage metrics
  - Test the output from any line to stdout
  - Use assert_cmd too
  - Test before the folder is not available
  - Inside this new folder create a new markdown file with the name project_path.md
  - And project_path.md follows these properties and fills in the current data with the hardware now in used
    - name of project
    - start date
    - used os
    - used hardware
    - used rust version
  - Generate a changelog.md file
  - Write for all function a documentation inside the code
  - Use comments to make code more readable
  - Use a hashmap to store data
  - Build the project with cargo
  - Create a demo exampleCreate a program with the following function and observe the following conditions

- Function
  
  The program is to be started on the command line
  be started and request a character string as input and
  output this in capital letters on the command line.
  The program should then be terminated. The return value of the BASH command of the program should then be output

- Testing:
  - Unit tests for core functionality
  - Integration tests for CLI behavior
  - 100% test coverage requirement
  - Coverage reporting setup
  - Line Coverage reporting setup
  
### Documentation Requirements

1. Code Documentation:
   - Rustdoc comments for public APIs
   - Examples in documentation
   - Clear error messages

2. Project Documentation:
   - README.md with usage instructions
   - CHANGELOG.md following Keep a Changelog format
   - License file (MIT)

### Quality Standards

1. Code must:
   - Pass `cargo clippy` without warnings
   - Be formatted with `cargo fmt`
   - Have no unsafe code
   - Include error handling for all failure cases

### Deliverables

1. Source code
2. Documentation
3. Tests
4. Coverage reports
5. Line coverage reports
6. Build scripts
7. Example usage