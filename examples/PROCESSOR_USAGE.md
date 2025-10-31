# Processor Feature - Quick Start Guide

## Overview

The processor feature allows you to create custom Ruby classes that dynamically generate options for `select` and `multi_select` fields based on:
- Previous user answers
- External data sources (files, APIs, databases)
- Complex business logic

## Quick Example

### 1. Define Your Processor

**For Rails** - Add to `config/initializers/prompter.rb`:

```ruby
class FeatureFlagProcessor
  def self.filter_by_release(answers:, config:)
    require 'yaml'

    features = YAML.load_file(config['data_file'])
    release_version = answers['release_version']

    # Your logic here to filter flags based on version
    # Return an array of options
    flags = []
    # ... filtering logic ...
    flags
  end
end
```

**For Ruby Projects** - Add to `config/prompter.rb` or create in `lib/processors/`:

```ruby
# lib/processors/feature_flag_processor.rb
class FeatureFlagProcessor
  def self.filter_by_release(answers:, config:)
    # Same as above
  end
end

# Then require in config/prompter.rb:
require_relative '../lib/processors/feature_flag_processor'
```

### 2. Use in Your Schema

```yaml
release_version:
  type: select
  prompt: "Select release version"
  options: ["3.1.5.1", "3.1.5.3", "3.2.0.0"]

feature_flags:
  type: multi_select
  prompt: "Select feature flags"
  source:
    type: "processor"              # Use processor type
    class: "FeatureFlagProcessor"  # Your class name
    method: "filter_by_release"    # Your method name
    data_file: "features.yml"      # Custom config param
```

### 3. Run Prompter

```ruby
Prompter.run('config/prompts/schema.yml', 'config/output.yml')
```

## How It Works

1. **User answers the first question** (e.g., selects "3.1.5.1")
2. **Prompter reaches the processor field**
3. **Calls your processor** with:
   - `answers: { 'release_version' => '3.1.5.1' }`
   - `config: { 'data_file' => 'features.yml' }`
4. **Your processor returns** `['flag1', 'flag2', 'flag3', 'flag4']`
5. **User sees** those options in the multi_select prompt

## Real-World Use Cases

### Use Case 1: Conditional Options Based on Environment

```ruby
class DeploymentProcessor
  def self.get_targets(answers:, config:)
    case answers['environment']
    when 'development'
      ['local', 'dev-server']
    when 'staging'
      ['staging-1', 'staging-2']
    when 'production'
      ['prod-us-east', 'prod-us-west', 'prod-eu']
    else
      []
    end
  end
end
```

Schema:
```yaml
environment:
  type: select
  prompt: "Select environment"
  options: ["development", "staging", "production"]

deployment_target:
  type: select
  prompt: "Select deployment target"
  source:
    type: "processor"
    class: "DeploymentProcessor"
    method: "get_targets"
```

### Use Case 2: Fetch from API

```ruby
class CloudRegionProcessor
  def self.fetch_available_regions(answers:, config:)
    require 'net/http'
    require 'json'

    url = config['api_url']
    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    data['regions'].map { |r| r['name'] }
  rescue StandardError => e
    puts "API error: #{e.message}"
    ['us-east-1', 'us-west-2']  # Fallback options
  end
end
```

Schema:
```yaml
cloud_provider:
  type: select
  options: ["aws", "gcp", "azure"]

region:
  type: select
  prompt: "Select region"
  source:
    type: "processor"
    class: "CloudRegionProcessor"
    method: "fetch_available_regions"
    api_url: "https://api.cloud-provider.com/regions"
```

### Use Case 3: Database Query (Rails)

```ruby
class UserProcessor
  def self.load_active_users(answers:, config:)
    team_id = answers['team_id']

    User.where(team_id: team_id, active: true)
        .order(:name)
        .pluck(:email)
  rescue StandardError => e
    puts "Database error: #{e.message}"
    []
  end
end
```

Schema:
```yaml
team_id:
  type: string
  prompt: "Enter team ID"

team_members:
  type: multi_select
  prompt: "Select team members"
  source:
    type: "processor"
    class: "UserProcessor"
    method: "load_active_users"
```

### Use Case 4: File-based Dynamic Options

```ruby
class ConfigProcessor
  def self.load_options(answers:, config:)
    require 'yaml'

    # Load different config based on environment
    env = answers['environment']
    file = "config/#{env}_options.yml"

    return [] unless File.exist?(file)

    data = YAML.load_file(file)
    data['available_options'] || []
  end
end
```

## Best Practices

### 1. Always Handle Errors

```ruby
def self.my_method(answers:, config:)
  # Your logic
rescue StandardError => e
  puts "Error: #{e.message}"
  []  # Return empty array on error
end
```

### 2. Validate Inputs

```ruby
def self.my_method(answers:, config:)
  required_field = answers['required_field']
  return [] unless required_field  # Guard clause

  # Continue with logic
end
```

### 3. Provide Fallbacks

```ruby
def self.fetch_from_api(answers:, config:)
  # Try to fetch from API
  options = make_api_call(config['api_url'])
rescue StandardError
  # Fallback to static options
  options = ['default_option_1', 'default_option_2']
end
```

### 4. Use Descriptive Names

```ruby
# Good
class FeatureFlagProcessor
  def self.filter_by_release(answers:, config:)

# Bad
class Processor
  def self.process(answers:, config:)
```

### 5. Document Your Processors

```ruby
# Filters feature flags based on release version
#
# @param answers [Hash] Contains 'release_version' key
# @param config [Hash] Contains 'data_file' key with path to YAML
# @return [Array<String>] List of available feature flags
def self.filter_by_release(answers:, config:)
```

## Testing Your Processors

Create a test file to verify your processor works:

```ruby
# test/processors/feature_flag_processor_test.rb
require 'test_helper'

class FeatureFlagProcessorTest < ActiveSupport::TestCase
  test "returns correct flags for version 3.1.5.1" do
    answers = { 'release_version' => '3.1.5.1' }
    config = { 'data_file' => 'test/fixtures/features.yml' }

    result = FeatureFlagProcessor.filter_by_release(
      answers: answers,
      config: config
    )

    assert_equal ['flag1', 'flag2', 'flag3', 'flag4'], result
  end
end
```

## Debugging Tips

### Enable Verbose Output

Add debug statements in your processor:

```ruby
def self.my_method(answers:, config:)
  puts "DEBUG: Received answers: #{answers.inspect}"
  puts "DEBUG: Received config: #{config.inspect}"

  # Your logic
  result = compute_options

  puts "DEBUG: Returning options: #{result.inspect}"
  result
end
```

### Test Processor Independently

```ruby
# In rails console or irb
require_relative 'config/initializers/prompter'

answers = { 'release_version' => '3.1.5.1' }
config = { 'data_file' => 'features.yml' }

result = FeatureFlagProcessor.filter_by_release(
  answers: answers,
  config: config
)

puts result.inspect
```

## Common Pitfalls

### [BAD] Forgetting to Handle Missing Answers

```ruby
def self.my_method(answers:, config:)
  version = answers['version']  # Could be nil!
  data[version]  # Error if version is nil
end
```

### [GOOD] Always Check for Presence

```ruby
def self.my_method(answers:, config:)
  version = answers['version']
  return [] unless version  # Guard clause

  data[version] || []
end
```

### [BAD] Using Instance Variables or State

```ruby
class BadProcessor
  @cache = {}  # Don't do this!

  def self.my_method(answers:, config:)
    @cache[answers['key']] = 'value'  # Stateful!
  end
end
```

### [GOOD] Keep Processors Stateless

```ruby
class GoodProcessor
  def self.my_method(answers:, config:)
    # All logic based on inputs only
    compute_result(answers, config)
  end
end
```

## Examples in This Repository

- `examples/processors/feature_flag_processor.rb` - Complete feature flag filtering example
- `examples/processors/README.md` - Detailed processor documentation
- `examples/processor_test.yml` - Schema using processors
- `examples/test_processor.rb` - Automated test suite

## Getting Help

If you encounter issues:

1. Check that your processor class is loaded before running Prompter
2. Verify the class name and method name match exactly in your schema
3. Add debug output to see what data your processor receives
4. Test your processor independently in Rails console/irb
5. Check the error messages - they indicate if class/method not found

## Summary

Processors give you unlimited flexibility to generate dynamic options:

- Access previous answers
- Load from external sources
- Apply complex business logic
- Keep schemas clean and maintainable
- Reusable across multiple schemas
- Easy to test

Define once, use everywhere!
