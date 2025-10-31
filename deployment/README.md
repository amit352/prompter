# Prompter Deployment

This directory contains the default configuration schema and deployment files for Prompter.

## Files

- `schema.yml` - Default configuration schema (customize this for your needs)
- `output.yml` - Generated configuration output (created after running Prompter)

## Usage

### Using Docker Compose (Recommended)

From the project root directory:

```bash
# Run Prompter with default schema
docker-compose run --rm prompter

# Run with custom schema file
docker-compose run --rm prompter my-schema.yml my-output.yml

# Access interactive shell
docker-compose run --rm prompter-shell --profile dev
```

### Without Docker

```bash
# From project root
ruby -Ilib bin/prompter deployment/schema.yml deployment/output.yml

# Or if gem is installed
prompter deployment/schema.yml deployment/output.yml
```

## Customizing the Schema

1. Edit `schema.yml` to define your configuration prompts
2. Add conditional logic with `skip_if`
3. Use processors for dynamic options (see examples/processors/)
4. Run Prompter to generate your configuration

## Schema Features

The default schema demonstrates:

- **Basic types**: string, integer, boolean, select, multi_select, hash
- **Validation**: regex patterns and lambda validators
- **Conditional fields**: Using `skip_if` to show/hide based on previous answers
- **Nested configurations**: Hash type with children
- **Sibling dependencies**: Children accessing other children via `answers.dig()`

## Example: Adding a Processor

If you want to use custom processors for dynamic options:

1. Create your processor in the parent directory or mount it
2. Load it in your schema:

```yaml
my_field:
  type: multi_select
  source:
    type: "processor"
    class: "MyProcessor"
    method: "get_options"
    custom_param: "value"
```

3. Define the processor before running Prompter

## Output

After running Prompter:
- Answers are saved to `output.yml` (or your specified output file)
- The file contains all your configuration in YAML format
- Use this file in your application for configuration

## Tips

- Use meaningful prompt text for better user experience
- Add `help` text to explain complex options
- Use `required: true` for mandatory fields
- Leverage `skip_if` to create dynamic workflows
- Test your schema with different input scenarios
