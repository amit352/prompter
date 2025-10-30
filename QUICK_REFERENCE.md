# Prompter Quick Reference Card

A cheat sheet for quickly building Prompter schemas. Print or keep handy while developing.

## Basic Structure

```yaml
field_name:
  type: string              # Required
  prompt: "Question text"   # Required
  default: "value"          # Optional
  required: true            # Optional
```

## Field Types

| Type | Description | Example |
|------|-------------|---------|
| `string` | Text input | `name`, `email`, `url` |
| `integer` | Numeric input | `port`, `count`, `age` |
| `boolean` | Yes/No question | `enable_ssl`, `debug_mode` |
| `select` | Single choice | `environment`, `region` |
| `multi_select` | Multiple choices | `features`, `plugins` |
| `hash` | Nested config | `database`, `server` |

## String Type

```yaml
username:
  type: string
  prompt: "Username:"
  default: "admin"
  required: true
  validate: "/^[a-z0-9_]+$/i"
  transform: "->(val) { val.downcase }"
```

## Integer Type

```yaml
port:
  type: integer
  prompt: "Port:"
  default: 3000
  validate: "->(val) { val > 0 && val < 65536 }"
```

## Boolean Type

```yaml
enable_ssl:
  type: boolean
  prompt: "Enable SSL?"
  default: false
```

## Select Type

```yaml
environment:
  type: select
  prompt: "Environment:"
  choices:
    - development
    - staging
    - production
  default: development
```

## Multi-Select Type

```yaml
features:
  type: multi_select
  prompt: "Select features:"
  choices:
    - auth
    - logging
    - monitoring
```

## Hash Type (Nested)

```yaml
database:
  type: hash
  prompt: "Database Config"
  children:
    host:
      type: string
      prompt: "Host:"
      default: localhost
    port:
      type: integer
      prompt: "Port:"
      default: 5432
```

## Common Validations

### Email
```yaml
email:
  type: string
  validate: "/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i"
```

### URL
```yaml
url:
  type: string
  validate: "/^https?:\\/\\/.+/"
```

### Port Number
```yaml
port:
  type: integer
  validate: "->(val) { val > 0 && val < 65536 }"
```

### Password (8+ chars)
```yaml
password:
  type: string
  validate: "->(val) { val.length >= 8 }"
```

### Password (Strong)
```yaml
password:
  type: string
  validate: "->(val) { val.length >= 8 && val =~ /[A-Z]/ && val =~ /[0-9]/ }"
```

### Alphanumeric
```yaml
code:
  type: string
  validate: "/^[a-zA-Z0-9]+$/"
```

### Not Empty
```yaml
name:
  type: string
  validate: "->(val) { !val.empty? }"
```

### Range
```yaml
age:
  type: integer
  validate: "->(val) { val >= 18 && val <= 120 }"
```

## Conditional Logic

### Skip if False
```yaml
ssl_cert:
  type: string
  skip_if: "->(answers) { !answers['enable_ssl'] }"
```

### Skip if Not Equal
```yaml
k8s_namespace:
  type: string
  skip_if: "->(answers) { answers['deployment'] != 'kubernetes' }"
```

### Skip if Not in Array
```yaml
email:
  type: string
  skip_if: "->(answers) { !answers['channels']&.include?('email') }"
```

### Skip Nested Value
```yaml
db_host:
  type: string
  skip_if: "->(answers) { answers.dig('db', 'type') == 'sqlite' }"
```

### Multiple Conditions (OR)
```yaml
field:
  type: string
  skip_if: "->(answers) { answers['env'] == 'dev' || !answers['enable'] }"
```

### Multiple Conditions (AND)
```yaml
field:
  type: string
  skip_if: "->(answers) { answers['env'] == 'prod' && answers['type'] == 'simple' }"
```

## Transformations

### Lowercase
```yaml
email:
  type: string
  transform: "->(val) { val.downcase }"
```

### Uppercase
```yaml
code:
  type: string
  transform: "->(val) { val.upcase }"
```

### Strip Whitespace
```yaml
name:
  type: string
  transform: "->(val) { val.strip }"
```

### Combined
```yaml
slug:
  type: string
  transform: "->(val) { val.downcase.strip.gsub(/\\s+/, '-') }"
```

## Type Conversion

### To Integer
```yaml
timeout:
  type: string
  convert: int
```

### To Float
```yaml
price:
  type: string
  convert: float
```

## Dynamic Options

### From Files
```yaml
theme:
  type: select
  prompt: "Theme:"
  source:
    type: files
    path: "themes/"
    extension: ".yml"
```

### From YAML
```yaml
region:
  type: select
  prompt: "Region:"
  source:
    type: yaml
    path: "data/regions.yml"
```

### From Proc
```yaml
branch:
  type: select
  prompt: "Branch:"
  source:
    type: proc
    value: "->{ `git branch`.split('\\n').map(&:strip) }"
```

## Common Patterns

### Environment-Based Config
```yaml
environment:
  type: select
  prompt: "Environment:"
  choices: [dev, staging, prod]

debug:
  type: boolean
  prompt: "Debug?"
  skip_if: "->(answers) { answers['environment'] == 'prod' }"
```

### Feature Flags
```yaml
features:
  type: multi_select
  prompt: "Features:"
  choices: [auth, logging, cache]

log_level:
  type: select
  prompt: "Log level:"
  choices: [debug, info, warn, error]
  skip_if: "->(answers) { !answers['features']&.include?('logging') }"
```

### Cloud Provider
```yaml
provider:
  type: select
  prompt: "Provider:"
  choices: [aws, azure, gcp]

aws_region:
  type: select
  prompt: "AWS Region:"
  choices: [us-east-1, us-west-2]
  skip_if: "->(answers) { answers['provider'] != 'aws' }"
```

## CLI Commands

```bash
# Show help
prompter --help

# Show examples
prompter --examples

# Show version
prompter --version

# Run with schema
prompter schema.yml output.yml

# Run with defaults (if configured)
prompter
```

## Installation

### Rails
```bash
rails generate prompter:install
```

### Ruby
```bash
rake prompter:install
```

## Configuration

### Rails
```ruby
# config/initializers/prompter.rb
Prompter.configure do |config|
  config.schema_path = Rails.root.join("config", "prompts", "schema.yml").to_s
  config.output_path = Rails.root.join("config", "generated.yml").to_s
end
```

### Ruby
```ruby
# config/prompter.rb
Prompter.configure do |config|
  config.schema_path = File.join(__dir__, "prompts", "schema.yml")
  config.output_path = File.join(__dir__, "generated.yml")
end
```

## API Usage

```ruby
# Run with paths
Prompter.run('schema.yml', 'output.yml')

# Run with configured defaults
Prompter.run

# Returns hash of answers
answers = Prompter.run('schema.yml')
# => { "name" => "value", ... }
```

## Troubleshooting

### Validation Always Fails
❌ `validate: "/^[\w]+$/"`
✅ `validate: "/^[\\w]+$/"`
*Escape backslashes in YAML*

### Skip Condition Not Working
❌ `skip_if: "->(answers) { !answers[key] }"`
✅ `skip_if: "->(answers) { !answers['key'] }"`
*Use string keys*

### Nested Access
❌ `answers['db']['host']`
✅ `answers.dig('db', 'host')`
*Use dig for safe access*

### Multi-Select Check
❌ `answers['channels'] == 'email'`
✅ `answers['channels']&.include?('email')`
*Multi-select returns array*

## Field Options Reference

| Option | Type | Description | Example |
|--------|------|-------------|---------|
| `type` | String | Field type *(required)* | `string`, `integer` |
| `prompt` | String | Question text *(required)* | `"Enter name:"` |
| `default` | Any | Default value | `"localhost"` |
| `required` | Boolean | Must provide value | `true` |
| `validate` | String | Regex or lambda | `"/^\\d+$/"` |
| `transform` | String | Lambda to transform | `"->(v) { v.upcase }"` |
| `convert` | String | Type conversion | `int`, `float` |
| `confirm` | Boolean | Ask for confirmation | `true` |
| `skip_if` | String | Conditional skip | `"->(a) { !a['enable'] }"` |
| `source` | Hash | Dynamic options | See dynamic options |
| `children` | Hash | Nested fields (hash type) | See hash type |
| `choices` | Array | Options (select types) | `[a, b, c]` |

## Common Field Combinations

### Required String with Validation
```yaml
email:
  type: string
  prompt: "Email:"
  required: true
  validate: "/^[\\w+\\-.]+@[a-z\\d\\-.]+\\.[a-z]+$/i"
```

### Integer with Range
```yaml
port:
  type: integer
  prompt: "Port (1024-65535):"
  default: 3000
  validate: "->(val) { val > 1024 && val < 65536 }"
```

### Conditional String
```yaml
enable_feature:
  type: boolean
  prompt: "Enable feature?"

api_key:
  type: string
  prompt: "API Key:"
  required: true
  skip_if: "->(answers) { !answers['enable_feature'] }"
```

### Select with Default
```yaml
environment:
  type: select
  prompt: "Environment:"
  choices: [development, staging, production]
  default: development
```

---

**For detailed documentation:** See [SCHEMA_GUIDE.md](SCHEMA_GUIDE.md)

**For examples:** See `examples/` directory

**For full features:** See [README.md](README.md)
