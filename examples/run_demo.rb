#!/usr/bin/env ruby
# Demo script to run Prompter with processor feature

require_relative '../lib/prompter'
require_relative 'processors/feature_flag_processor'

puts "=" * 70
puts "  PROMPTER PROCESSOR DEMO"
puts "=" * 70
puts
puts "This demo shows how processors dynamically filter options based on"
puts "your previous answers."
puts
puts "You'll first select a release version, then the available feature"
puts "flags will be filtered based on that version."
puts
puts "=" * 70
puts

# Run prompter with the processor schema
schema_path = File.join(__dir__, 'processor_test.yml')
output_path = File.join(__dir__, 'demo_output.yml')

answers = Prompter.run(schema_path, output_path)

puts "\n" + "=" * 70
puts "Demo completed! Check the results:"
puts "=" * 70
puts
puts "Output saved to: #{output_path}"
puts
puts "Final configuration:"
puts "-" * 70
puts YAML.dump(answers)
