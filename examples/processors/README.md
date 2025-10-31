# Prompter Processors

Processors are custom Ruby classes that dynamically generate options for select/multi_select fields based on user's previous answers.

## When to Use Processors

Use processors when you need to:
- Filter options based on previous answers
- Load data from external sources (APIs, databases)
- Apply complex business logic to generate options
- Transform or compute options dynamically

## Creating a Processor

A processor is a Ruby class with class methods that accept two parameters:

```ruby
class MyProcessor
  def self.my_method(answers:, config:)
    # answers - Hash of all previous user answers
    # config - Hash of configuration from schema

    # Return an array of options
    ["option1", "option2", "option3"]
  end
end
```

## Using Processors in Schemas

```yaml
my_field:
  type: multi_select
  prompt: "Select options"
  source:
    type: "processor"
    class: "MyProcessor"         # Class name
    method: "my_method"           # Method name
    custom_param: "value"         # Any additional params
```

## Examples

### 1. Feature Flag Processor (see feature_flag_processor.rb)

Filters available feature flags based on selected release version.

```ruby
class FeatureFlagProcessor
  def self.filter_by_release(answers:, config:)
    # Load data file specified in config
    features = YAML.load_file(config['data_file'])

    # Get release version from previous answers
    version = answers['release_version']

    # Return filtered flags
    # ...
  end
end
```

### 2. API Processor

Fetch options from an external API:

```ruby
class ApiProcessor
  def self.fetch_regions(answers:, config:)
    require 'net/http'
    require 'json'

    url = config['api_url']
    response = Net::HTTP.get(URI(url))
    data = JSON.parse(response)

    data['regions'].map { |r| r['name'] }
  rescue StandardError => e
    puts "API fetch failed: #{e.message}"
    []
  end
end
```

Schema usage:
```yaml
cloud_region:
  type: select
  prompt: "Select cloud region"
  source:
    type: "processor"
    class: "ApiProcessor"
    method: "fetch_regions"
    api_url: "https://api.example.com/regions"
```

### 3. Database Processor (Rails/ActiveRecord)

Load options from database:

```ruby
class DatabaseProcessor
  def self.load_active_users(answers:, config:)
    User.where(active: true)
        .order(:name)
        .pluck(:name)
  rescue StandardError => e
    puts "Database query failed: #{e.message}"
    []
  end
end
```

### 4. Conditional Options Processor

Different options based on previous answer:

```ruby
class ConditionalProcessor
  def self.get_deployment_targets(answers:, config:)
    environment = answers['environment']

    case environment
    when 'development'
      ['local', 'dev-server']
    when 'staging'
      ['staging-1', 'staging-2']
    when 'production'
      ['prod-cluster-1', 'prod-cluster-2', 'prod-cluster-3']
    else
      []
    end
  end
end
```

## Loading Processors

### In Rails Projects

Define processors in `config/initializers/prompter.rb`:

```ruby
# config/initializers/prompter.rb

Prompter.configure do |config|
  config.schema_path = Rails.root.join('config/prompts/schema.yml')
  config.output_path = Rails.root.join('config/generated_config.yml')
end

# Define processors here
class MyProcessor
  def self.my_method(answers:, config:)
    # ...
  end
end
```

### In Ruby Projects

Create processor files in `lib/processors/` and require them:

```ruby
# lib/processors/my_processor.rb
class MyProcessor
  def self.my_method(answers:, config:)
    # ...
  end
end

# config/prompter.rb
require_relative '../lib/processors/my_processor'

Prompter.configure do |config|
  config.schema_path = 'config/prompts/schema.yml'
  config.output_path = 'config/generated_config.yml'
end
```

## Best Practices

1. **Always handle errors**: Return empty array on failure
2. **Validate inputs**: Check that required answers exist
3. **Document parameters**: Comment what config params are expected
4. **Keep it simple**: Complex logic should be in separate classes
5. **Return arrays**: Always return an array of strings
6. **Use config for flexibility**: Pass file paths, URLs, etc. via config

## Error Handling

Processors should always return an array and handle errors gracefully:

```ruby
def self.my_method(answers:, config:)
  # Validate required answers
  return [] unless answers['required_field']

  # Your logic here
  result = compute_options(answers, config)

  result
rescue StandardError => e
  puts "Processor error: #{e.message}"
  []
end
```

## Testing Processors

Since processors are plain Ruby classes, they're easy to test:

```ruby
RSpec.describe FeatureFlagProcessor do
  describe '.filter_by_release' do
    it 'returns flags for version 3.1.5.1' do
      answers = { 'release_version' => '3.1.5.1' }
      config = { 'data_file' => 'spec/fixtures/features.yml' }

      result = described_class.filter_by_release(answers: answers, config: config)

      expect(result).to include('flag1', 'flag2')
    end
  end
end
```
