# frozen_string_literal: true

require 'rails/generators/base'

module Prompter
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc "Creates a Prompter initializer and example schema files"

      def copy_initializer
        template "prompter.rb", "config/initializers/prompter.rb"
      end

      def create_prompt_directory
        empty_directory "config/prompts"
      end

      def copy_example_schema
        template "example_schema.yml", "config/prompts/example_schema.yml"
      end

      def show_readme
        readme "USAGE" if behavior == :invoke
      end
    end
  end
end
