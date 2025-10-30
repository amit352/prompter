# Prompter Schema Guide

Complete guide to creating YAML schemas for Prompter. This document serves as a comprehensive reference for building interactive configuration prompts.

## Table of Contents

1. [Introduction](#introduction)
2. [Schema Structure](#schema-structure)
3. [Step-by-Step Tutorial](#step-by-step-tutorial)
4. [Field Types Reference](#field-types-reference)
5. [Validation Patterns](#validation-patterns)
6. [Conditional Logic](#conditional-logic)
7. [Dynamic Options](#dynamic-options)
8. [Common Patterns](#common-patterns)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## Introduction

A Prompter schema is a YAML file that defines a series of interactive prompts. Each field in your schema becomes a prompt shown to the user. The schema structure is simple but powerful, allowing you to create complex configuration workflows.

### Basic Schema Structure

```yaml
field_name:
  type: string
  prompt: "Question to ask the user"
  default: "default value"
  required: true
```

**Key Components:**
- `field_name`: The key in the output hash
- `type`: What kind of input to collect
- `prompt`: The question shown to the user
- Additional options for validation, defaults, etc.

## Schema Structure

### Anatomy of a Schema Field

```yaml
field_name:                    # Output key name
  type: string                 # Field type (required)
  prompt: "Enter value:"       # Question text (required)
  default: "default"           # Pre-filled value
  required: true               # Must be provided
  validate: "/regex/"          # Validation pattern
  transform: "->(val) {...}"   # Transform input
  convert: int                 # Type conversion
  confirm: true                # Ask for confirmation
  skip_if: "->(answers) {...}" # Conditional display
```

### Output Format

The schema generates a hash that's saved to YAML:

```ruby
# Input schema
name:
  type: string
  prompt: "Name:"

# Output
{ "name" => "John" }

# Saved as YAML
---
name: John
```

## Step-by-Step Tutorial

### Tutorial 1: Simple Application Configuration

Let's build a schema from scratch for a basic web application.

#### Step 1: Define Basic Information

```yaml
# config/prompts/app_config.yml

# Application name
app_name:
  type: string
  prompt: "What is your application name?"
  required: true
```

**What this does:**
- Creates a text input prompt
- Makes it mandatory
- Stores result in `app_name` key

#### Step 2: Add Environment Selection

```yaml
app_name:
  type: string
  prompt: "What is your application name?"
  required: true

# Add environment selection
environment:
  type: select
  prompt: "Select environment:"
  choices:
    - development
    - staging
    - production
  default: development
```

**What this does:**
- Shows a dropdown menu
- Limits choices to 3 options
- Defaults to "development"

#### Step 3: Add Port Configuration

```yaml
app_name:
  type: string
  prompt: "What is your application name?"
  required: true

environment:
  type: select
  prompt: "Select environment:"
  choices:
    - development
    - staging
    - production
  default: development

# Add port number
port:
  type: integer
  prompt: "Port number:"
  default: 3000
  validate: "->(val) { val > 0 && val < 65536 }"
```

**What this does:**
- Accepts numeric input
- Validates port is in valid range (1-65535)
- Defaults to 3000

#### Step 4: Add Conditional Feature

```yaml
app_name:
  type: string
  prompt: "What is your application name?"
  required: true

environment:
  type: select
  prompt: "Select environment:"
  choices:
    - development
    - staging
    - production
  default: development

port:
  type: integer
  prompt: "Port number:"
  default: 3000
  validate: "->(val) { val > 0 && val < 65536 }"

# Add SSL option
enable_ssl:
  type: boolean
  prompt: "Enable SSL?"
  default: false

# Conditional SSL certificate path
ssl_cert_path:
  type: string
  prompt: "SSL certificate path:"
  default: "/etc/ssl/certs/cert.pem"
  skip_if: "->(answers) { !answers['enable_ssl'] }"
```

**What this does:**
- `enable_ssl`: Yes/No question
- `ssl_cert_path`: Only shown if SSL is enabled
- Uses `skip_if` for conditional logic

#### Step 5: Add Nested Database Configuration

```yaml
app_name:
  type: string
  prompt: "What is your application name?"
  required: true

environment:
  type: select
  prompt: "Select environment:"
  choices:
    - development
    - staging
    - production
  default: development

port:
  type: integer
  prompt: "Port number:"
  default: 3000
  validate: "->(val) { val > 0 && val < 65536 }"

enable_ssl:
  type: boolean
  prompt: "Enable SSL?"
  default: false

ssl_cert_path:
  type: string
  prompt: "SSL certificate path:"
  default: "/etc/ssl/certs/cert.pem"
  skip_if: "->(answers) { !answers['enable_ssl'] }"

# Nested database configuration
database:
  type: hash
  prompt: "Database Configuration"
  children:
    adapter:
      type: select
      prompt: "Database adapter:"
      choices:
        - postgresql
        - mysql
        - sqlite3
      default: postgresql

    host:
      type: string
      prompt: "Database host:"
      default: localhost

    port:
      type: integer
      prompt: "Database port:"
      default: 5432

    name:
      type: string
      prompt: "Database name:"
      required: true
```

**What this does:**
- Creates a nested structure
- Groups related database settings
- Each child field works like a top-level field

#### Complete Example Output

```yaml
---
app_name: my_awesome_app
environment: production
port: 8080
enable_ssl: true
ssl_cert_path: "/etc/ssl/certs/cert.pem"
database:
  adapter: postgresql
  host: db.example.com
  port: 5432
  name: myapp_production
```

### Tutorial 2: Multi-Environment Configuration

Build a schema that adapts based on environment selection.

```yaml
# Select environment first
environment:
  type: select
  prompt: "Select environment:"
  choices:
    - development
    - staging
    - production
  default: development

# Debug mode (only in development)
debug_mode:
  type: boolean
  prompt: "Enable debug mode?"
  default: true
  skip_if: "->(answers) { answers['environment'] != 'development' }"

# Load balancer (only in production)
use_load_balancer:
  type: boolean
  prompt: "Use load balancer?"
  default: true
  skip_if: "->(answers) { answers['environment'] != 'production' }"

# Number of instances (only if load balancer enabled)
instance_count:
  type: integer
  prompt: "Number of instances:"
  default: 3
  validate: "->(val) { val > 0 && val <= 10 }"
  skip_if: "->(answers) { !answers['use_load_balancer'] }"

# Monitoring (staging and production only)
enable_monitoring:
  type: boolean
  prompt: "Enable monitoring?"
  default: true
  skip_if: "->(answers) { answers['environment'] == 'development' }"
```

## Field Types Reference

### 1. String Type

The most common type for text input.

```yaml
# Basic string
username:
  type: string
  prompt: "Enter username:"

# With default
api_url:
  type: string
  prompt: "API URL:"
  default: "https://api.example.com"

# Required string
email:
  type: string
  prompt: "Email address:"
  required: true

# With validation
slug:
  type: string
  prompt: "URL slug:"
  validate: "/^[a-z0-9-]+$/"

# With transformation
tag:
  type: string
  prompt: "Enter tag:"
  transform: "->(val) { val.downcase.strip }"
```

**Common Use Cases:**
- URLs, paths, names
- Email addresses
- API keys and tokens
- Custom identifiers

### 2. Integer Type

For numeric input (whole numbers).

```yaml
# Basic integer
port:
  type: integer
  prompt: "Port number:"
  default: 3000

# With range validation
timeout:
  type: integer
  prompt: "Timeout (seconds):"
  default: 30
  validate: "->(val) { val >= 1 && val <= 300 }"

# Required integer
max_connections:
  type: integer
  prompt: "Max connections:"
  required: true
  validate: "->(val) { val > 0 }"
```

**Common Use Cases:**
- Port numbers
- Timeouts and intervals
- Counts and limits
- Years, quantities

### 3. Boolean Type

For yes/no questions.

```yaml
# Basic boolean
enable_cache:
  type: boolean
  prompt: "Enable caching?"
  default: true

# Without default (user must choose)
agree_terms:
  type: boolean
  prompt: "Do you agree to the terms?"
  required: true

# For feature flags
enable_feature_x:
  type: boolean
  prompt: "Enable experimental feature X?"
  default: false
```

**Common Use Cases:**
- Feature flags
- Enable/disable options
- Confirmations
- Yes/no decisions

### 4. Select Type

Single choice from a list.

```yaml
# Basic select
region:
  type: select
  prompt: "Select region:"
  choices:
    - us-east-1
    - us-west-2
    - eu-west-1
  default: us-east-1

# Without default
log_level:
  type: select
  prompt: "Log level:"
  choices:
    - debug
    - info
    - warn
    - error

# Required select
deployment_type:
  type: select
  prompt: "Deployment type:"
  choices:
    - docker
    - kubernetes
    - heroku
  required: true
```

**Common Use Cases:**
- Environment selection
- Region/location selection
- Mode or type selection
- Preset configurations

### 5. Multi-Select Type

Multiple choices from a list.

```yaml
# Basic multi-select
features:
  type: multi_select
  prompt: "Select features to enable:"
  choices:
    - authentication
    - logging
    - monitoring
    - caching
    - api

# Build stages
build_stages:
  type: multi_select
  prompt: "Select build stages:"
  choices:
    - lint
    - test
    - build
    - deploy
    - notify
```

**Common Use Cases:**
- Feature selection
- Plugin/module selection
- Build stages
- Notification channels
- Permission sets

### 6. Hash Type

Nested configuration groups.

```yaml
# Simple nested config
database:
  type: hash
  prompt: "Database Configuration"
  children:
    host:
      type: string
      prompt: "Host:"
      default: localhost
    port:
      type: integer
      prompt: "Port:"
      default: 5432

# Deeply nested config
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
        port:
          type: integer
          prompt: "Port:"
    worker:
      type: hash
      prompt: "Worker Server"
      children:
        threads:
          type: integer
          prompt: "Worker threads:"
```

**Common Use Cases:**
- Grouping related settings
- Multi-level configurations
- Service configurations
- Complex data structures

## Validation Patterns

### Regex Validation

Use regex patterns wrapped in quotes:

```yaml
# Email validation
email:
  type: string
  prompt: "Email:"
  validate: "/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i"

# Username (alphanumeric and underscore)
username:
  type: string
  prompt: "Username:"
  validate: "/^[a-zA-Z0-9_]+$/"

# URL validation
url:
  type: string
  prompt: "URL:"
  validate: "/^https?:\\/\\/.+/"

# Phone number (US format)
phone:
  type: string
  prompt: "Phone:"
  validate: "/^\\d{3}-\\d{3}-\\d{4}$/"

# IP address
ip_address:
  type: string
  prompt: "IP Address:"
  validate: "/^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$/"

# Semantic version
version:
  type: string
  prompt: "Version:"
  validate: "/^\\d+\\.\\d+\\.\\d+$/"
```

### Lambda Validation

Use lambda functions for complex validation:

```yaml
# Range validation
age:
  type: integer
  prompt: "Age:"
  validate: "->(val) { val >= 18 && val <= 120 }"

# Port number validation
port:
  type: integer
  prompt: "Port:"
  validate: "->(val) { val > 1024 && val < 65536 }"

# String length validation
password:
  type: string
  prompt: "Password:"
  validate: "->(val) { val.length >= 8 }"

# Complex password validation
secure_password:
  type: string
  prompt: "Password:"
  validate: "->(val) { val.length >= 8 && val =~ /[A-Z]/ && val =~ /[a-z]/ && val =~ /[0-9]/ }"

# Custom business logic
project_name:
  type: string
  prompt: "Project name:"
  validate: "->(val) { val.length >= 3 && !val.include?(' ') && val == val.downcase }"

# Conditional validation
max_value:
  type: integer
  prompt: "Maximum value:"
  validate: "->(val) { val > answers['min_value'] }"
```

### Validation Error Messages

Prompter will re-prompt if validation fails. Consider clear prompts:

```yaml
# Clear validation message in prompt
port:
  type: integer
  prompt: "Port number (1024-65535):"
  validate: "->(val) { val > 1024 && val < 65536 }"

password:
  type: string
  prompt: "Password (8+ chars, uppercase, lowercase, number):"
  validate: "->(val) { val.length >= 8 && val =~ /[A-Z]/ && val =~ /[a-z]/ && val =~ /[0-9]/ }"
```

## Conditional Logic

### Basic Skip Conditions

```yaml
# Skip based on boolean
enable_ssl:
  type: boolean
  prompt: "Enable SSL?"

ssl_cert:
  type: string
  prompt: "SSL certificate path:"
  skip_if: "->(answers) { !answers['enable_ssl'] }"
```

### Skip Based on Select Value

```yaml
deployment_type:
  type: select
  prompt: "Deployment:"
  choices: [docker, kubernetes, heroku]

# Only for Kubernetes
k8s_namespace:
  type: string
  prompt: "Kubernetes namespace:"
  skip_if: "->(answers) { answers['deployment_type'] != 'kubernetes' }"

# Only for Docker
docker_image:
  type: string
  prompt: "Docker image:"
  skip_if: "->(answers) { answers['deployment_type'] != 'docker' }"
```

### Skip Based on Nested Values

```yaml
database:
  type: hash
  prompt: "Database Config"
  children:
    adapter:
      type: select
      prompt: "Adapter:"
      choices: [postgresql, mysql, sqlite3]
    host:
      type: string
      prompt: "Host:"
      skip_if: "->(answers) { answers.dig('database', 'adapter') == 'sqlite3' }"
```

### Complex Conditions

```yaml
environment:
  type: select
  prompt: "Environment:"
  choices: [development, staging, production]

use_cdn:
  type: boolean
  prompt: "Use CDN?"
  default: false

# Skip if development OR if CDN is not enabled
cdn_url:
  type: string
  prompt: "CDN URL:"
  skip_if: "->(answers) { answers['environment'] == 'development' || !answers['use_cdn'] }"
```

### Multi-Level Conditionals

```yaml
enable_notifications:
  type: boolean
  prompt: "Enable notifications?"

notification_channels:
  type: multi_select
  prompt: "Select channels:"
  choices: [email, slack, webhook]
  skip_if: "->(answers) { !answers['enable_notifications'] }"

# Only if notifications enabled AND email selected
email_address:
  type: string
  prompt: "Email address:"
  skip_if: "->(answers) { !answers['enable_notifications'] || !answers['notification_channels']&.include?('email') }"

# Only if notifications enabled AND slack selected
slack_webhook:
  type: string
  prompt: "Slack webhook URL:"
  skip_if: "->(answers) { !answers['enable_notifications'] || !answers['notification_channels']&.include?('slack') }"
```

## Dynamic Options

### Loading from Files

```yaml
# Load YAML files from directory
theme:
  type: select
  prompt: "Select theme:"
  source:
    type: files
    path: "themes/"
    extension: ".yml"

# Load template files
template:
  type: select
  prompt: "Select template:"
  source:
    type: files
    path: "templates/"
    extension: ".rb"
```

**Directory Structure:**
```
themes/
  ├── dark.yml
  ├── light.yml
  └── custom.yml
```

**Result:** Choices will be `["dark", "light", "custom"]`

### Loading from YAML File

```yaml
# Single YAML file with array
region:
  type: select
  prompt: "Select region:"
  source:
    type: yaml
    path: "data/regions.yml"
```

**data/regions.yml:**
```yaml
- us-east-1
- us-west-2
- eu-west-1
- ap-southeast-1
```

### Loading from Proc

```yaml
# Load from environment variable
environment:
  type: select
  prompt: "Select environment:"
  source:
    type: proc
    value: "->{ ENV['AVAILABLE_ENVS'].split(',') }"

# Load from git branches
branch:
  type: select
  prompt: "Select branch:"
  source:
    type: proc
    value: "->{ `git branch -r`.split('\n').map(&:strip) }"

# Load from database (if available)
team:
  type: select
  prompt: "Select team:"
  source:
    type: proc
    value: "->{ Team.pluck(:name) }"
```

## Common Patterns

### Pattern 1: Environment-Specific Configuration

```yaml
environment:
  type: select
  prompt: "Environment:"
  choices: [development, staging, production]

debug:
  type: boolean
  prompt: "Debug mode?"
  default: true
  skip_if: "->(answers) { answers['environment'] == 'production' }"

replicas:
  type: integer
  prompt: "Number of replicas:"
  default: 1
  skip_if: "->(answers) { answers['environment'] == 'development' }"
  validate: "->(val) { val > 0 && val <= 10 }"
```

### Pattern 2: Feature Flag Configuration

```yaml
features:
  type: multi_select
  prompt: "Select features:"
  choices:
    - authentication
    - authorization
    - logging
    - monitoring
    - caching

# Authentication config (only if selected)
auth_provider:
  type: select
  prompt: "Auth provider:"
  choices: [oauth, jwt, session]
  skip_if: "->(answers) { !answers['features']&.include?('authentication') }"

# Logging config (only if selected)
log_level:
  type: select
  prompt: "Log level:"
  choices: [debug, info, warn, error]
  skip_if: "->(answers) { !answers['features']&.include?('logging') }"
```

### Pattern 3: Cloud Provider Configuration

```yaml
cloud_provider:
  type: select
  prompt: "Cloud provider:"
  choices: [aws, azure, gcp]

# AWS-specific
aws_region:
  type: select
  prompt: "AWS Region:"
  choices: [us-east-1, us-west-2, eu-west-1]
  skip_if: "->(answers) { answers['cloud_provider'] != 'aws' }"

# Azure-specific
azure_location:
  type: select
  prompt: "Azure Location:"
  choices: [eastus, westus, northeurope]
  skip_if: "->(answers) { answers['cloud_provider'] != 'azure' }"

# GCP-specific
gcp_zone:
  type: select
  prompt: "GCP Zone:"
  choices: [us-central1, us-east1, europe-west1]
  skip_if: "->(answers) { answers['cloud_provider'] != 'gcp' }"
```

### Pattern 4: Security Configuration

```yaml
security_level:
  type: select
  prompt: "Security level:"
  choices: [basic, standard, high]
  default: standard

# Basic: No extra config
# Standard: Add SSL
enable_ssl:
  type: boolean
  prompt: "Enable SSL?"
  default: true
  skip_if: "->(answers) { answers['security_level'] == 'basic' }"

ssl_cert_path:
  type: string
  prompt: "SSL certificate:"
  skip_if: "->(answers) { answers['security_level'] == 'basic' || !answers['enable_ssl'] }"

# High: Add firewall rules
enable_firewall:
  type: boolean
  prompt: "Enable firewall?"
  default: true
  skip_if: "->(answers) { answers['security_level'] != 'high' }"

allowed_ips:
  type: string
  prompt: "Allowed IPs (comma-separated):"
  skip_if: "->(answers) { answers['security_level'] != 'high' || !answers['enable_firewall'] }"
```

### Pattern 5: Multi-Service Configuration

```yaml
services:
  type: multi_select
  prompt: "Select services:"
  choices:
    - web
    - api
    - worker
    - scheduler

# Web service config
web:
  type: hash
  prompt: "Web Service Configuration"
  skip_if: "->(answers) { !answers['services']&.include?('web') }"
  children:
    port:
      type: integer
      prompt: "Port:"
      default: 3000
    workers:
      type: integer
      prompt: "Workers:"
      default: 2

# API service config
api:
  type: hash
  prompt: "API Service Configuration"
  skip_if: "->(answers) { !answers['services']&.include?('api') }"
  children:
    port:
      type: integer
      prompt: "Port:"
      default: 8080
    rate_limit:
      type: integer
      prompt: "Rate limit (req/min):"
      default: 100

# Worker service config
worker:
  type: hash
  prompt: "Worker Configuration"
  skip_if: "->(answers) { !answers['services']&.include?('worker') }"
  children:
    concurrency:
      type: integer
      prompt: "Concurrency:"
      default: 5
    queue:
      type: string
      prompt: "Queue name:"
      default: default
```

## Best Practices

### 1. Clear and Concise Prompts

**Bad:**
```yaml
val:
  type: string
  prompt: "Enter val:"
```

**Good:**
```yaml
api_key:
  type: string
  prompt: "Enter your API key:"
```

### 2. Provide Sensible Defaults

```yaml
# Good: Defaults for common choices
environment:
  type: select
  prompt: "Environment:"
  choices: [development, staging, production]
  default: development

port:
  type: integer
  prompt: "Port:"
  default: 3000
```

### 3. Use Validation Hints in Prompts

```yaml
# Include format in prompt
email:
  type: string
  prompt: "Email address (user@example.com):"
  validate: "/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i"

port:
  type: integer
  prompt: "Port number (1024-65535):"
  validate: "->(val) { val > 1024 && val < 65536 }"
```

### 4. Group Related Configuration

```yaml
# Use hash type for related settings
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
    name:
      type: string
      prompt: "Database name:"
```

### 5. Order Fields Logically

```yaml
# Start with high-level choices
environment:
  type: select
  prompt: "Environment:"
  choices: [development, staging, production]

# Then general config
app_name:
  type: string
  prompt: "App name:"

# Then specific config
port:
  type: integer
  prompt: "Port:"

# Finally, conditional/optional fields
enable_ssl:
  type: boolean
  prompt: "Enable SSL?"
```

### 6. Use Descriptive Field Names

**Bad:**
```yaml
val1:
  type: string
x:
  type: integer
```

**Good:**
```yaml
api_endpoint:
  type: string
max_retry_attempts:
  type: integer
```

### 7. Document Complex Schemas

```yaml
# Database configuration
# This section configures the primary database connection
database:
  type: hash
  prompt: "Database Configuration"
  children:
    # Connection settings
    host:
      type: string
      prompt: "Database host:"
      default: localhost
```

## Troubleshooting

### Common Issues

#### Issue 1: Validation Always Fails

**Problem:**
```yaml
email:
  type: string
  validate: "/^[\w+\-.]+@[a-z\d\-.]+\.[a-z]+$/i"
```

**Solution:** Escape backslashes in YAML strings:
```yaml
email:
  type: string
  validate: "/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i"
```

#### Issue 2: Skip Condition Not Working

**Problem:**
```yaml
ssl_cert:
  type: string
  skip_if: "->(answers) { !answers[enable_ssl] }"
```

**Solution:** Use string keys, not symbols:
```yaml
ssl_cert:
  type: string
  skip_if: "->(answers) { !answers['enable_ssl'] }"
```

#### Issue 3: Nested Field Access

**Problem:**
```yaml
port:
  type: integer
  skip_if: "->(answers) { answers['database']['adapter'] == 'sqlite3' }"
```

**Solution:** Use `dig` for safe nested access:
```yaml
port:
  type: integer
  skip_if: "->(answers) { answers.dig('database', 'adapter') == 'sqlite3' }"
```

#### Issue 4: Multi-Select Conditional

**Problem:**
```yaml
email:
  type: string
  skip_if: "->(answers) { answers['channels'] != 'email' }"
```

**Solution:** Multi-select returns an array, use `include?`:
```yaml
email:
  type: string
  skip_if: "->(answers) { !answers['channels']&.include?('email') }"
```

### Testing Your Schema

Test incrementally:

```bash
# Test with CLI
prompter your_schema.yml test_output.yml

# Test in Ruby
require 'prompter'
Prompter.run('your_schema.yml', 'test_output.yml')
```

### Debug Mode

Add print statements in lambdas:

```yaml
field:
  type: string
  skip_if: "->(answers) {
    puts 'DEBUG: answers = ' + answers.inspect
    !answers['enable']
  }"
```

## Quick Reference

### Field Type Cheat Sheet

```yaml
# String
name:
  type: string
  prompt: "Name:"

# Integer
count:
  type: integer
  prompt: "Count:"

# Boolean
enabled:
  type: boolean
  prompt: "Enable?"

# Select
option:
  type: select
  prompt: "Choose:"
  choices: [a, b, c]

# Multi-select
items:
  type: multi_select
  prompt: "Select items:"
  choices: [x, y, z]

# Hash (nested)
config:
  type: hash
  prompt: "Config"
  children:
    key:
      type: string
      prompt: "Key:"
```

### Common Validations

```yaml
# Email
validate: "/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i"

# URL
validate: "/^https?:\\/\\/.+/"

# Port
validate: "->(val) { val > 0 && val < 65536 }"

# Not empty
validate: "->(val) { !val.empty? }"

# Min length
validate: "->(val) { val.length >= 8 }"

# Alphanumeric
validate: "/^[a-zA-Z0-9]+$/"
```

### Conditional Examples

```yaml
# Skip if false
skip_if: "->(answers) { !answers['enable'] }"

# Skip if not equal
skip_if: "->(answers) { answers['type'] != 'custom' }"

# Skip if not in array
skip_if: "->(answers) { !answers['features']&.include?('auth') }"

# Skip nested value
skip_if: "->(answers) { answers.dig('db', 'type') == 'sqlite' }"

# Multiple conditions
skip_if: "->(answers) { answers['env'] == 'dev' || !answers['enable'] }"
```

## Advanced Examples

See the `examples/` directory for complete, runnable schemas:

- `examples/simple_test.yml` - Basic configuration
- `examples/full_feature_test.yml` - All features demonstrated
- `examples/README.md` - Detailed explanations

## Getting Help

- Run `prompter --help` for CLI help
- Run `prompter --examples` for usage examples
- Check [README.md](README.md) for full documentation
- Report issues on GitHub

---

**Happy Schema Building! 🚀**
