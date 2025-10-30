# frozen_string_literal: true

# Prompter Configuration
# This initializer sets up default paths for your Prompter schema and output files.
#
# For more information on configuration options, see:
# https://github.com/yourusername/prompter

Prompter.configure do |config|
  # Path to your YAML schema file
  # This defines the prompts and validations for your configuration
  config.schema_path = Rails.root.join("config", "prompts", "schema.yml").to_s

  # Path where the generated configuration YAML will be saved
  # Set to nil if you don't want to save output to a file
  config.output_path = Rails.root.join("config", "generated_config.yml").to_s
end

# Custom Processors
# ----------------
# Define custom processor classes here to dynamically generate options
# based on user's previous answers.
#
# Example processor that filters options based on previous answer:
#
# class MyCustomProcessor
#   def self.filter_options(answers:, config:)
#     # Access previous answers
#     selected_value = answers['previous_field']
#
#     # Access config params from schema
#     data_file = config['data_file']
#
#     # Return array of options
#     case selected_value
#     when 'option_a'
#       ['item1', 'item2']
#     when 'option_b'
#       ['item3', 'item4', 'item5']
#     else
#       []
#     end
#   rescue StandardError => e
#     puts "Processor error: #{e.message}"
#     []
#   end
# end
#
# Usage in schema (config/prompts/schema.yml):
#
#   my_field:
#     type: multi_select
#     prompt: "Select items"
#     source:
#       type: "processor"
#       class: "MyCustomProcessor"
#       method: "filter_options"
#       data_file: "config/data.yml"

# Usage:
# ------
# After configuring, you can run Prompter in several ways:
#
# 1. Use configured defaults:
#    Prompter.run
#
# 2. Override schema path (uses configured output_path):
#    Prompter.run("path/to/custom/schema.yml")
#
# 3. Override both paths:
#    Prompter.run("path/to/custom/schema.yml", "path/to/custom/output.yml")
#
# 4. Run without saving output:
#    Prompter.run("path/to/schema.yml", nil)
