# Prompter Testing Suite

This directory contains comprehensive test files to demonstrate all features of the Prompter gem.

## Directory Structure

```
testing/
├── README.md                    # This file
├── simple_test.yml              # Simple test schema (quick start)
├── full_feature_test.yml        # Comprehensive test schema
├── sample_scripts/              # Sample deployment scripts
│   ├── deploy_aws.sh
│   ├── deploy_azure.sh
│   ├── deploy_docker.sh
│   ├── deploy_gcp.sh
│   └── deploy_heroku.sh
└── data/
    └── environments.yml         # Sample environment configurations
```

## Running the Tests

### Quick Start (Simple Test)

For a quick test with basic features:

```bash
# From repository root
ruby -Ilib bin/prompter testing/simple_test.yml testing/simple_output.yml

# If gem is installed
prompter testing/simple_test.yml testing/simple_output.yml
```

### Full Feature Test

For comprehensive testing of all features:

```bash
# From repository root with output file
ruby -Ilib bin/prompter testing/full_feature_test.yml testing/output.yml

# Without output file (just see the prompts)
ruby -Ilib bin/prompter testing/full_feature_test.yml

# If gem is installed
prompter testing/full_feature_test.yml testing/output.yml
```

## Test Files

### simple_test.yml

A quick test schema with basic features:
- String input with validation
- Boolean input
- Conditional hash (database config shown only if database is needed)
- Select from files (deployment scripts)

Perfect for a quick demo or learning the basics.

### full_feature_test.yml

A comprehensive schema demonstrating all Prompter features. See detailed feature list below.

## Features Demonstrated (in full_feature_test.yml)

### 1. Basic String Input with Validation
**Field:** `project_name`
- Validates using regex pattern (lowercase, numbers, hyphens only)
- Has default value
- Required field
- Includes help text

### 2. Integer Input
**Field:** `max_connections`
- Accepts integer values
- Automatic type conversion
- Default value provided

### 3. String Input with Confirmation
**Field:** `api_key`
- Requires user confirmation
- Useful for sensitive or critical values
- Required field

### 4. Boolean Input
**Field:** `enable_caching`
- Yes/No question
- Default value

### 5. Select from Files
**Field:** `deployment_script`
- Dynamically loads options from `sample_scripts/` directory
- Uses `source.type: "files"`
- Displays all files in the specified directory

### 6. Select from YAML
**Field:** `environment`
- Loads options from `data/environments.yml`
- Uses `source.type: "yaml"`
- Extracts keys from YAML hash

### 7. Multi-Select
**Field:** `features`
- Allows multiple selections
- Has default selections
- Static options list

### 8. String Transformation
**Field:** `domain_name`
- Automatically converts to lowercase
- Uses lambda transformation
- Validates with regex

### 9. Type Conversion
**Field:** `timeout_seconds`
- Converts string to float
- Validates using lambda function
- Checks value range

### 10. Conditional Hash (Nested Configuration)
**Field:** `cache_config`
- Only shown if `enable_caching` is true
- Uses `skip_if` with lambda
- Contains nested children fields:
  - `cache_type` (select)
  - `cache_ttl` (integer)
  - `cache_size_mb` (integer)

### 11. Conditional Based on Multi-Select
**Field:** `auth_settings`
- Only shown if "Authentication" is selected in `features`
- Demonstrates checking array membership
- Nested hash with multiple configuration options

**Field:** `logging_config`
- Only shown if "Logging" is selected in `features`
- Another example of conditional nested configuration

### 12. Dynamic Options with Proc
**Field:** `random_option`
- Uses `source.type: "proc"`
- Options generated at runtime using lambda
- Demonstrates programmatic option generation

### 13. Complex Regex Validation
**Field:** `email_address`
- Validates email format
- Required field
- Complex regex pattern

### 14. Range Validation
**Field:** `server_port`
- Validates port number range (1024-65535)
- Uses lambda validator
- Converts to integer

## Testing Different Scenarios

### Test Scenario 1: Enable All Features
1. Answer "yes" to `enable_caching`
2. Select "Authentication" and "Logging" in `features`
3. Observe that `cache_config`, `auth_settings`, and `logging_config` are all displayed

### Test Scenario 2: Minimal Configuration
1. Answer "no" to `enable_caching`
2. Deselect all features in `features` (or select only non-conditional ones)
3. Observe that conditional sections are skipped

### Test Scenario 3: Test Validation
1. Try entering invalid project name (e.g., with uppercase or spaces) - should fail validation
2. Try entering invalid email - should fail validation
3. Try entering port number outside range - should fail validation

### Test Scenario 4: Test Confirmation
1. Enter an API key
2. When asked to confirm, answer "no"
3. Observe that you're asked to enter the API key again

### Test Scenario 5: Test Transformation
1. Enter domain name with uppercase letters and spaces
2. Observe that it's automatically converted to lowercase and trimmed

## Expected Output

After completing all prompts, the gem will:
1. Display a summary of all answers
2. Save the configuration to `testing/output.yml` (if output path provided)

The output YAML will contain all answered fields in a structured format that can be used as application configuration.

## Modifying Tests

You can modify `full_feature_test.yml` to test additional scenarios:

- Add new validation rules
- Test different conditional logic
- Add more complex nested structures
- Test edge cases

## Notes

- All lambda expressions in `skip_if`, `validate`, `transform`, etc. are evaluated using `eval()`
- The `answers` hash passed to lambdas contains all previously answered questions
- Source paths are relative to where the prompter command is executed
