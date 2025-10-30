require "yaml"
require "tty-prompt"
require_relative "prompter/runner"

module Prompter
  def self.run(schema_path, output_path = nil)
    runner = Runner.new(schema_path)
    answers = runner.run
    if output_path
      File.write(output_path, YAML.dump(answers))
      puts "\n Configuration saved to #{output_path}"
    end
    answers
  end
end
