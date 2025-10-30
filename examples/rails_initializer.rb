# frozen_string_literal: true

# Example Rails initializer for Prompter gem
# Place this file in: config/initializers/prompter.rb

Prompter.configure do |config|
  # Path to your YAML schema file
  # This can be a relative path from your Rails root, or an absolute path
  config.schema_path = Rails.root.join("config", "prompts", "schema.yml").to_s

  # Path where the generated configuration YAML will be saved
  # This can also be relative or absolute
  config.output_path = Rails.root.join("config", "generated_config.yml").to_s
end

# After configuring, you can run Prompter without specifying paths:
#
# In a Rails console or rake task:
#   Prompter.run
#
# Or override the configured paths:
#   Prompter.run("path/to/custom/schema.yml", "path/to/custom/output.yml")
