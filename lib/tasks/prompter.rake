# frozen_string_literal: true

require 'fileutils'

namespace :prompter do
  desc "Initialize Prompter with example configuration files"
  task :install do
    base_dir = defined?(Rails) ? Rails.root : Dir.pwd

    puts "Installing Prompter..."

    # Create config directory structure
    config_dir = File.join(base_dir, "config")
    prompts_dir = File.join(config_dir, "prompts")

    FileUtils.mkdir_p(prompts_dir)
    puts "  create  #{prompts_dir}"

    # Copy initializer (for Rails) or config file (for Ruby)
    if defined?(Rails)
      initializer_path = File.join(config_dir, "initializers", "prompter.rb")
      FileUtils.mkdir_p(File.dirname(initializer_path))

      unless File.exist?(initializer_path)
        File.write(initializer_path, initializer_template(rails: true))
        puts "  create  #{initializer_path}"
      else
        puts "  exists  #{initializer_path}"
      end
    else
      config_path = File.join(config_dir, "prompter.rb")

      unless File.exist?(config_path)
        File.write(config_path, initializer_template(rails: false))
        puts "  create  #{config_path}"
      else
        puts "  exists  #{config_path}"
      end
    end

    # Copy example schema
    schema_path = File.join(prompts_dir, "example_schema.yml")
    unless File.exist?(schema_path)
      File.write(schema_path, example_schema_template)
      puts "  create  #{schema_path}"
    else
      puts "  exists  #{schema_path}"
    end

    puts "\nPrompter installed successfully!"
    puts "\nNext steps:"
    if defined?(Rails)
      puts "  1. Review config/initializers/prompter.rb"
      puts "  2. Customize config/prompts/example_schema.yml"
      puts "  3. Run in Rails console: Prompter.run"
    else
      puts "  1. Review config/prompter.rb"
      puts "  2. Require it in your application: require_relative 'config/prompter'"
      puts "  3. Customize config/prompts/example_schema.yml"
      puts "  4. Run: Prompter.run"
    end
  end

  def initializer_template(rails:)
    if rails
      <<~RUBY
        # frozen_string_literal: true

        # Prompter Configuration
        Prompter.configure do |config|
          # Path to your YAML schema file
          config.schema_path = Rails.root.join("config", "prompts", "example_schema.yml").to_s

          # Path where the generated configuration YAML will be saved
          config.output_path = Rails.root.join("config", "generated_config.yml").to_s
        end
      RUBY
    else
      <<~RUBY
        # frozen_string_literal: true

        require 'prompter'

        # Prompter Configuration
        Prompter.configure do |config|
          # Path to your YAML schema file
          config.schema_path = File.join(__dir__, "prompts", "example_schema.yml")

          # Path where the generated configuration YAML will be saved
          config.output_path = File.join(__dir__, "generated_config.yml")
        end
      RUBY
    end
  end

  def example_schema_template
    <<~YAML
      # Example Prompter Schema
      # Customize this to create your own configuration prompts

      app_name:
        type: string
        prompt: "What is your application name?"
        required: true
        validate: "/^[a-z_]+$/"
        default: my_app

      environment:
        type: select
        prompt: "Select your environment:"
        choices:
          - development
          - staging
          - production
        default: development

      enable_feature:
        type: boolean
        prompt: "Enable new feature?"
        default: false

      max_connections:
        type: integer
        prompt: "Maximum number of connections:"
        default: 10
        validate: "->(val) { val > 0 && val <= 100 }"

      features:
        type: multi_select
        prompt: "Select features to enable:"
        choices:
          - authentication
          - logging
          - monitoring
          - caching

      database:
        type: hash
        prompt: "Database Configuration"
        children:
          host:
            type: string
            prompt: "Database host:"
            default: localhost
          port:
            type: integer
            prompt: "Database port:"
            default: 5432
    YAML
  end
end
