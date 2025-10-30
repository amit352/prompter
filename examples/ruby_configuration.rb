# frozen_string_literal: true

# Example configuration for standalone Ruby projects
# Place this in your application initialization code

require 'prompter'

# Configure Prompter with default paths
Prompter.configure do |config|
  config.schema_path = File.join(__dir__, "config", "prompts", "schema.yml")
  config.output_path = File.join(__dir__, "config", "generated_config.yml")
end

# Usage examples:

# 1. Run with configured defaults
answers = Prompter.run

# 2. Run with custom schema path (uses configured output_path)
answers = Prompter.run("custom/schema.yml")

# 3. Run with both custom paths (ignores configured defaults)
answers = Prompter.run("custom/schema.yml", "custom/output.yml")

# 4. Run without output file (just return answers)
Prompter.configure do |config|
  config.schema_path = "my_schema.yml"
  config.output_path = nil  # No output file
end
answers = Prompter.run
