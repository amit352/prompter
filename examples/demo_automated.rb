#!/usr/bin/env ruby
# Automated demo showing processor feature in action

require_relative '../lib/prompter'
require_relative 'processors/feature_flag_processor'
require 'yaml'

puts "\n" + "=" * 70
puts "  PROMPTER PROCESSOR FEATURE - AUTOMATED DEMO"
puts "=" * 70
puts
puts "This demo shows how processors dynamically generate options based"
puts "on previous answers. We'll simulate 3 different scenarios."
puts "=" * 70

# Helper to simulate what the processor will return
def show_scenario(version)
  puts "\n" + "-" * 70
  puts "SCENARIO: User selects release version '#{version}'"
  puts "-" * 70

  # Simulate the processor being called
  answers = { 'release_version' => version }
  config = { 'data_file' => File.join(__dir__, 'features.yml') }

  puts "\n1. User answers: release_version = '#{version}'"
  puts "\n2. Prompter reaches 'feature_flags' field with processor source"
  puts "\n3. Processor is called:"
  puts "   Class: FeatureFlagProcessor"
  puts "   Method: filter_by_release"
  puts "   Arguments:"
  puts "     answers: #{answers.inspect}"
  puts "     config: #{config.inspect}"

  puts "\n4. Processor executes and loads features.yml..."

  # Call the actual processor
  available_flags = FeatureFlagProcessor.filter_by_release(
    answers: answers,
    config: config
  )

  puts "\n5. Processor returns: #{available_flags.inspect}"
  puts "\n6. User sees these #{available_flags.length} options in the multi_select prompt:"
  available_flags.each_with_index do |flag, idx|
    puts "   #{idx + 1}. #{flag}"
  end

  puts "\n[OK] Processor successfully filtered options based on release version!"
end

# Show all three scenarios
show_scenario('3.1.5.1')
show_scenario('3.1.5.3')
show_scenario('3.2.0.0')

# Show the features.yml structure
puts "\n\n" + "=" * 70
puts "FEATURES DATA FILE STRUCTURE"
puts "=" * 70
puts
features = YAML.load_file(File.join(__dir__, 'features.yml'))
puts YAML.dump(features)

# Explain the logic
puts "=" * 70
puts "PROCESSOR LOGIC EXPLANATION"
puts "=" * 70
puts
puts "Version 3.1.5.1:"
puts "  → Includes flags from: 3.1.5.0 + 3.1.5.1"
puts "  → Returns: flag1, flag2, flag3, flag4"
puts
puts "Version 3.1.5.3:"
puts "  → Includes flags from: 3.1.5.0 + 3.1.5.1 + 3.1.5.2 + 3.1.5.3"
puts "  → Returns: flag1, flag2, flag3, flag4, flag5, flag6, flag7, flag8"
puts
puts "Version 3.2.0.0:"
puts "  → Includes ALL available flags"
puts "  → Returns: flag1, flag2, flag3, flag4, flag5, flag6, flag7, flag8"
puts
puts "=" * 70
puts "This demonstrates how processors enable dynamic, context-aware prompts!"
puts "=" * 70
puts
