# frozen_string_literal: true

module Prompter
  # Configuration class for managing Prompter default settings
  class Configuration
    attr_accessor :schema_path, :output_path

    def initialize
      @schema_path = nil
      @output_path = nil
    end

    # Reset configuration to defaults
    def reset!
      @schema_path = nil
      @output_path = nil
    end
  end
end
