# Prompter

An interactive YAML-driven configuration prompting system for Ruby and Rails applications. Prompter reads a YAML schema file and interactively prompts users to generate validated configuration files using TTY::Prompt.

## Table of Contents

- [Documentation](#documentation)
- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [CLI Usage](#cli-usage)
- [Configuration](#configuration)
- [Schema Definition](#schema-definition)
- [Field Types](#field-types)
- [Field Options](#field-options)
- [Advanced Features](#advanced-features)
- [Real-World Examples](#real-world-examples)
- [API Reference](#api-reference)
- [Development](#development)
- [Contributing](#contributing)

## Documentation

📚 **Comprehensive Guides:**

- **[Schema Guide](SCHEMA_GUIDE.md)** - Complete guide to building schemas
  - Step-by-step tutorials
  - Field type deep dives
  - Validation patterns
  - Conditional logic examples
  - Common patterns and best practices
  - Troubleshooting guide

- **[Quick Reference](QUICK_REFERENCE.md)** - Printable cheat sheet
  - Field type syntax
  - Common validations
  - Conditional examples
  - CLI commands
  - Quick lookup table

- **[Examples](examples/)** - Real-world schema examples
  - `simple_test.yml` - Basic configuration
  - `full_feature_test.yml` - All features demonstrated
  - `README.md` - Detailed explanations

💡 **CLI Help:**
```bash
prompter --help      # Full documentation
prompter --examples  # Usage examples
prompter --version   # Version info
```

## Features

- **Interactive Prompts**: User-friendly CLI prompts powered by TTY::Prompt
- **Type System**: Support for string, integer, boolean, select, multi_select, and nested hash types
- **Validation**: Built-in validation with regex patterns or custom lambda functions
- **Conditional Logic**: Skip fields based on previous answers using `skip_if`
- **Transformations**: Transform user input with lambda functions
- **Dynamic Options**: Load select/multi_select choices from files, YAML, or procs
- **Nested Configurations**: Create structured configurations with nested hash fields
- **Rails Integration**: Rails generator and initializer support
- **Default Values**: Pre-fill prompts with sensible defaults
- **Required Fields**: Mark fields as mandatory
- **Confirmation**: Ask users to confirm sensitive inputs
- **Type Conversion**: Automatic type conversion (int, float)
- **Configuration Management**: Set default paths for schema and output files
- **CLI Tool**: Full-featured command-line interface with help and examples

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prompter'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install prompter
```

## Quick Start

### Rails Projects

After installing the gem, run the generator to set up Prompter:

```bash
rails generate prompter:install
```

This creates:
- `config/initializers/prompter.rb` - Configuration initializer
- `config/prompts/` - Directory for your schema files
- `config/prompts/example_schema.yml` - Example schema file

Then run Prompter in your Rails console:

```ruby
rails console
> Prompter.run
```

### Ruby Projects

For standalone Ruby projects, use the rake task:

```bash
rake prompter:install
```

This creates:
- `config/prompter.rb` - Configuration file
- `config/prompts/` - Directory for your schema files
- `config/prompts/example_schema.yml` - Example schema file

Then require the configuration in your application:

```ruby
require_relative 'config/prompter'
Prompter.run
```

### Command Line Usage

You can also use the CLI directly without configuration:

```bash
# Show help
prompter --help

# Show version
prompter --version

# Show examples
prompter --examples

# Run with explicit paths
prompter schema.yml output.yml

# Run with schema only (just returns data, no file output)
prompter schema.yml
```

## CLI Usage

The prompter CLI provides comprehensive help and examples:

```bash
prompter --help      # Show full help documentation
prompter --version   # Show version number
prompter --examples  # Show detailed usage examples
```

### CLI Commands

```bash
# Basic usage with output file
prompter config/schema.yml config/output.yml

# Run without output file (returns data only)
prompter config/schema.yml

# Use configured defaults (requires configuration setup)
prompter
```

## Configuration

Prompter supports a configuration system that allows you to set default paths for your schema and output files.

### Rails Configuration

If you didn't use the generator, manually create an initializer in `config/initializers/prompter.rb`:

```ruby
Prompter.configure do |config|
  config.schema_path = Rails.root.join("config", "prompts", "schema.yml").to_s
  config.output_path = Rails.root.join("config", "generated_config.yml").to_s
end
```

Then you can use Prompter without specifying paths:

```ruby
# In a Rails console or rake task
Prompter.run

# Or override the configured paths
Prompter.run("custom/schema.yml", "custom/output.yml")
```

### Standalone Ruby Configuration

```ruby
require 'prompter'

Prompter.configure do |config|
  config.schema_path = File.join(__dir__, "config", "schema.yml")
  config.output_path = File.join(__dir__, "config", "output.yml")
end

# Use configured defaults
answers = Prompter.run

# Override schema path only (uses configured output_path)
answers = Prompter.run("custom/schema.yml")

# Override both paths
answers = Prompter.run("custom/schema.yml", "custom/output.yml")
```

### Configuration Options

- `schema_path`: Path to the YAML schema file containing prompt definitions
- `output_path`: Path where the generated configuration YAML will be saved (optional)

## Schema Definition

> 📖 **For detailed schema building guidance, see [SCHEMA_GUIDE.md](SCHEMA_GUIDE.md)** - includes step-by-step tutorials, patterns, and troubleshooting.

Create a YAML schema file that defines your prompts. Here's a comprehensive example:

```yaml
# String input with validation
app_name:
  type: string
  prompt: "What is your application name?"
  required: true
  validate: "/^[a-z_]+$/"
  default: my_app

# Single select dropdown
environment:
  type: select
  prompt: "Select environment:"
  choices:
    - development
    - staging
    - production
  default: development

# Boolean (yes/no) question
enable_caching:
  type: boolean
  prompt: "Enable caching?"
  default: true

# Integer input with validation
max_connections:
  type: integer
  prompt: "Maximum number of connections:"
  default: 10
  validate: "->(val) { val > 0 && val <= 100 }"

# Multiple selection
features:
  type: multi_select
  prompt: "Select features to enable:"
  choices:
    - authentication
    - logging
    - monitoring
    - api

# Nested configuration
database:
  type: hash
  prompt: "Database Configuration"
  children:
    host:
      type: string
      prompt: "Database host:"
      default: localhost
      required: true
    port:
      type: integer
      prompt: "Database port:"
      default: 5432
    use_ssl:
      type: boolean
      prompt: "Use SSL for database connection?"
      default: true

# Conditional field (only shown if database.use_ssl is true)
ssl_cert_path:
  type: string
  prompt: "Path to SSL certificate:"
  skip_if: "->(answers) { !answers.dig('database', 'use_ssl') }"
  default: "/etc/ssl/certs"
```

## Field Types

Prompter supports six field types:

### 1. String
Text input with optional validation and transformation.

```yaml
username:
  type: string
  prompt: "Enter username:"
  required: true
  validate: "/^[a-z0-9_]+$/i"
```

### 2. Integer
Numeric input with automatic type conversion.

```yaml
port:
  type: integer
  prompt: "Enter port number:"
  default: 3000
  validate: "->(val) { val > 0 && val < 65536 }"
```

### 3. Boolean
Yes/No questions returning true/false.

```yaml
enable_ssl:
  type: boolean
  prompt: "Enable SSL?"
  default: true
```

### 4. Select
Single choice from a list of options.

```yaml
region:
  type: select
  prompt: "Select AWS region:"
  choices:
    - us-east-1
    - us-west-2
    - eu-west-1
  default: us-east-1
```

### 5. Multi-Select
Multiple choices from a list of options.

```yaml
features:
  type: multi_select
  prompt: "Select features:"
  choices:
    - feature_a
    - feature_b
    - feature_c
```

### 6. Hash
Nested configuration with child fields.

```yaml
database:
  type: hash
  prompt: "Database Configuration"
  children:
    host:
      type: string
      prompt: "Host:"
    port:
      type: integer
      prompt: "Port:"
```

## Field Options

### Core Options

- **`type`** (required): Field type - string, integer, boolean, select, multi_select, hash
- **`prompt`** (required): Question text shown to user
- **`default`**: Default value pre-filled in prompt
- **`required`**: Whether input is mandatory (boolean)

### Validation Options

- **`validate`**: Regex pattern (`"/pattern/"`) or lambda (`"->(val) { ... }"`)
  ```yaml
  email:
    type: string
    validate: "/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i"

  age:
    type: integer
    validate: "->(val) { val >= 18 }"
  ```

### Transformation Options

- **`transform`**: Lambda to transform user input
  ```yaml
  code:
    type: string
    transform: "->(val) { val.upcase.strip }"
  ```

- **`convert`**: Type conversion - int, float
  ```yaml
  price:
    type: string
    convert: float
  ```

### Conditional Options

- **`skip_if`**: Lambda that receives `answers` hash and returns boolean
  ```yaml
  ssl_cert:
    type: string
    skip_if: "->(answers) { !answers['use_ssl'] }"
  ```

- **`confirm`**: Ask user to confirm value (boolean)
  ```yaml
  api_key:
    type: string
    confirm: true
  ```

### Dynamic Options

- **`source`**: Load select/multi_select choices dynamically

  **From files:**
  ```yaml
  theme:
    type: select
    prompt: "Select theme:"
    source:
      type: files
      path: "themes/"
      extension: ".yml"
  ```

  **From YAML:**
  ```yaml
  region:
    type: select
    prompt: "Select region:"
    source:
      type: yaml
      path: "data/regions.yml"
  ```

  **From proc:**
  ```yaml
  environment:
    type: select
    prompt: "Select environment:"
    source:
      type: proc
      value: "->{ ENV['AVAILABLE_ENVS'].split(',') }"
  ```

### Nested Options

- **`children`**: For hash type, nested field definitions
  ```yaml
  server:
    type: hash
    children:
      host:
        type: string
      port:
        type: integer
  ```

## Advanced Features

### 1. Conditional Fields

Skip fields based on previous answers:

```yaml
deployment_type:
  type: select
  prompt: "Select deployment type:"
  choices:
    - docker
    - kubernetes
    - heroku

kubernetes_namespace:
  type: string
  prompt: "Kubernetes namespace:"
  skip_if: "->(answers) { answers['deployment_type'] != 'kubernetes' }"

heroku_app_name:
  type: string
  prompt: "Heroku app name:"
  skip_if: "->(answers) { answers['deployment_type'] != 'heroku' }"
```

### 2. Complex Validation

Use lambda functions for complex validation logic:

```yaml
password:
  type: string
  prompt: "Enter password:"
  validate: "->(val) { val.length >= 8 && val =~ /[A-Z]/ && val =~ /[0-9]/ }"
  required: true

port:
  type: integer
  prompt: "Enter port:"
  validate: "->(val) { (1024..65535).include?(val) }"
```

### 3. Nested Hash Configurations

Create deeply nested configurations:

```yaml
server:
  type: hash
  prompt: "Server Configuration"
  children:
    web:
      type: hash
      prompt: "Web Server"
      children:
        host:
          type: string
          prompt: "Host:"
          default: "0.0.0.0"
        port:
          type: integer
          prompt: "Port:"
          default: 3000
    database:
      type: hash
      prompt: "Database"
      children:
        host:
          type: string
          prompt: "DB Host:"
        port:
          type: integer
          prompt: "DB Port:"
          default: 5432
```

### 4. Dynamic Option Loading

Load options from various sources:

**From directory files:**
```yaml
template:
  type: select
  prompt: "Select deployment template:"
  source:
    type: files
    path: "templates/deployment/"
    extension: ".yml"
```

**From YAML file:**
```yaml
# data/aws_regions.yml contains: [us-east-1, us-west-2, eu-west-1]
aws_region:
  type: select
  prompt: "Select AWS region:"
  source:
    type: yaml
    path: "data/aws_regions.yml"
```

**From proc:**
```yaml
git_branch:
  type: select
  prompt: "Select branch:"
  source:
    type: proc
    value: "->{ `git branch -r`.split('\n').map(&:strip) }"
```

### 5. Input Transformation

Transform user input before saving:

```yaml
# Convert to uppercase
country_code:
  type: string
  prompt: "Enter country code:"
  transform: "->(val) { val.upcase }"

# Strip whitespace and downcase
email:
  type: string
  prompt: "Enter email:"
  transform: "->(val) { val.strip.downcase }"

# Custom transformation
slug:
  type: string
  prompt: "Enter title:"
  transform: "->(val) { val.downcase.gsub(/\\s+/, '-') }"
```

### 6. Type Conversion

Convert string inputs to other types:

```yaml
price:
  type: string
  prompt: "Enter price:"
  convert: float
  validate: "->(val) { val > 0 }"

timeout:
  type: string
  prompt: "Enter timeout (seconds):"
  convert: int
  default: "30"
```

## Real-World Examples

### Example 1: Application Configuration

```yaml
app_name:
  type: string
  prompt: "Application name:"
  required: true
  validate: "/^[a-z][a-z0-9_]*$/"

environment:
  type: select
  prompt: "Environment:"
  choices: [development, staging, production]
  default: development

log_level:
  type: select
  prompt: "Log level:"
  choices: [debug, info, warn, error]
  default: info

enable_metrics:
  type: boolean
  prompt: "Enable metrics collection?"
  default: true

metrics_port:
  type: integer
  prompt: "Metrics server port:"
  default: 9090
  skip_if: "->(answers) { !answers['enable_metrics'] }"
```

### Example 2: Database Configuration

```yaml
database:
  type: hash
  prompt: "Database Configuration"
  children:
    adapter:
      type: select
      prompt: "Database adapter:"
      choices: [postgresql, mysql, sqlite3]
      default: postgresql

    host:
      type: string
      prompt: "Database host:"
      default: localhost
      skip_if: "->(answers) { answers.dig('database', 'adapter') == 'sqlite3' }"

    port:
      type: integer
      prompt: "Database port:"
      default: 5432
      skip_if: "->(answers) { answers.dig('database', 'adapter') == 'sqlite3' }"

    database:
      type: string
      prompt: "Database name:"
      required: true

    pool:
      type: integer
      prompt: "Connection pool size:"
      default: 5
      validate: "->(val) { val > 0 && val <= 100 }"
```

### Example 3: AWS Deployment Configuration

```yaml
aws_region:
  type: select
  prompt: "AWS Region:"
  choices:
    - us-east-1
    - us-west-2
    - eu-west-1
    - ap-southeast-1

instance_type:
  type: select
  prompt: "EC2 instance type:"
  choices:
    - t3.micro
    - t3.small
    - t3.medium
    - t3.large

enable_auto_scaling:
  type: boolean
  prompt: "Enable auto-scaling?"
  default: false

min_instances:
  type: integer
  prompt: "Minimum instances:"
  default: 1
  skip_if: "->(answers) { !answers['enable_auto_scaling'] }"
  validate: "->(val) { val > 0 }"

max_instances:
  type: integer
  prompt: "Maximum instances:"
  default: 5
  skip_if: "->(answers) { !answers['enable_auto_scaling'] }"
  validate: "->(val) { val > answers['min_instances'] }"

enable_monitoring:
  type: boolean
  prompt: "Enable CloudWatch monitoring?"
  default: true
```

### Example 4: CI/CD Pipeline Configuration

```yaml
pipeline_name:
  type: string
  prompt: "Pipeline name:"
  required: true
  validate: "/^[a-z][a-z0-9-]*$/"

repository_url:
  type: string
  prompt: "Git repository URL:"
  required: true
  validate: "/^https?:\\/\\/.+\\.git$/"

branch:
  type: string
  prompt: "Branch to deploy:"
  default: main

build_stages:
  type: multi_select
  prompt: "Select build stages:"
  choices:
    - lint
    - test
    - build
    - security_scan
    - deploy

deployment_target:
  type: select
  prompt: "Deployment target:"
  choices:
    - staging
    - production
  skip_if: "->(answers) { !answers['build_stages'].include?('deploy') }"

notify_on_failure:
  type: boolean
  prompt: "Send notifications on failure?"
  default: true

notification_channels:
  type: multi_select
  prompt: "Notification channels:"
  choices:
    - email
    - slack
    - webhook
  skip_if: "->(answers) { !answers['notify_on_failure'] }"
```

## API Reference

### Prompter Module

#### `.configure`
Configure default paths for schema and output files.

```ruby
Prompter.configure do |config|
  config.schema_path = "config/schema.yml"
  config.output_path = "config/output.yml"
end
```

#### `.configuration`
Access the current configuration.

```ruby
Prompter.configuration.schema_path
# => "config/schema.yml"
```

#### `.reset_configuration!`
Reset configuration to defaults.

```ruby
Prompter.reset_configuration!
```

#### `.run(schema_path = nil, output_path = nil)`
Run the prompter with optional paths. Returns a hash of answers.

```ruby
# Use configured paths
answers = Prompter.run

# Override schema path
answers = Prompter.run("custom/schema.yml")

# Override both paths
answers = Prompter.run("custom/schema.yml", "custom/output.yml")
```

**Parameters:**
- `schema_path` (String, optional): Path to YAML schema file
- `output_path` (String, optional): Path to save generated YAML

**Returns:** Hash of user answers

**Raises:** `ArgumentError` if schema_path is not provided or configured

### Prompter::Configuration

#### `#schema_path`
Get/set the default schema file path.

```ruby
config.schema_path = "path/to/schema.yml"
```

#### `#output_path`
Get/set the default output file path.

```ruby
config.output_path = "path/to/output.yml"
```

#### `#reset!`
Reset configuration attributes to nil.

```ruby
config.reset!
```

## Development

```bash
# Setup
bundle install

# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/prompter_spec.rb

# Manual testing with example schemas
ruby -Ilib bin/prompter examples/simple_test.yml output.yml
ruby -Ilib bin/prompter examples/full_feature_test.yml output.yml

# Build and install locally
gem build prompter.gemspec
gem install ./prompter-0.1.0.gem
```

## Security Note

The Runner uses `eval` to evaluate lambda expressions from YAML schemas. This is intentional for flexibility but means **schema files should be from trusted sources only**. Never allow untrusted users to provide schema files.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/prompter.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Changelog

### v0.1.0
- Initial release
- Support for 6 field types (string, integer, boolean, select, multi_select, hash)
- Validation with regex and lambda
- Conditional fields with skip_if
- Dynamic option loading from files, YAML, and procs
- Rails generator and initializer support
- Configuration management
- Comprehensive CLI with help and examples
- Nested hash configurations
- Input transformation and type conversion
