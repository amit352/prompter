require "yaml"
require "tty-prompt"
require_relative "prompter/version"
require_relative "prompter/runner"
require_relative "prompter/configuration"
require_relative "prompter/railtie" if defined?(Rails)

module Prompter
  class << self
    attr_writer :configuration

    # Get the current configuration
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure Prompter with a block
    #
    # @example
    #   Prompter.configure do |config|
    #     config.schema_path = 'config/prompts/schema.yml'
    #     config.output_path = 'config/generated.yml'
    #   end
    def configure
      yield(configuration)
    end

    # Reset configuration to defaults
    def reset_configuration!
      @configuration = Configuration.new
    end

    # Run the prompter with optional paths
    # If paths are not provided, uses configured defaults
    #
    # @param schema_path [String] Path to schema YAML file (optional if configured)
    # @param output_path [String] Path to output file (optional if configured)
    # @return [Hash] The collected answers
    def run(schema_path = nil, output_path = nil)
      schema_path ||= configuration.schema_path
      output_path ||= configuration.output_path

      raise ArgumentError, "schema_path must be provided or configured" unless schema_path

      runner = Runner.new(schema_path)
      answers = runner.run
      if output_path
        File.write(output_path, YAML.dump(answers))
        puts "\n Configuration saved to #{output_path}"
      end
      answers
    end
  end
end
