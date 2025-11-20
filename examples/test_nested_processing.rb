#!/usr/bin/env ruby
# Test to verify nested answers during hash processing

require_relative '../lib/prompter'
require 'tempfile'
require 'yaml'

puts "=" * 70
puts "Testing nested answers DURING hash processing"
puts "=" * 70
puts

# Schema with children that depend on other children in same hash
test_schema = {
  'pre_checks' => {
    'type' => 'hash',
    'prompt' => 'Pre-checks',
    'children' => {
      'allow_destructive_prime' => {
        'type' => 'boolean',
        'prompt' => 'Allow destructive operations?',
        'default' => false
      },
      # This child depends on previous sibling
      'confirm_destruction' => {
        'type' => 'boolean',
        'prompt' => 'Confirm you want to proceed with destruction?',
        'default' => false,
        'skip_if' => "->(answers) { !answers.dig('pre_checks', 'allow_destructive_prime') }"
      }
    }
  }
}

# Create temporary schema file
temp_file = Tempfile.new(['schema', '.yml'])
temp_file.write(test_schema.to_yaml)
temp_file.close

runner = Prompter::Runner.new(temp_file.path)

puts "Test: Child depending on sibling within same hash"
puts "-" * 70

# Start with empty answers (simulating actual run)
runner.instance_variable_set(:@answers, {})

puts "\nProcessing pre_checks hash..."
puts "First child: allow_destructive_prime = false"

# Process first child manually to simulate
runner.instance_variable_set(:@answers, {})
pre_checks_config = test_schema['pre_checks']
children_config = pre_checks_config['children']

# The problem: when ask_hash processes children, @answers is not updated
# So the second child's skip_if can't access first child's answer via dig

puts "\nChecking if confirm_destruction should be asked..."
puts "Current @answers: #{runner.answers.inspect}"
puts "Expected: pre_checks is not in @answers yet!"

confirm_config = children_config['confirm_destruction']
should_ask = runner.send(:should_ask?, confirm_config)

puts "should_ask confirm_destruction? #{should_ask}"
puts "Expected: true (because dig returns nil, not false)"

puts "\n" + "=" * 70
puts "ISSUE IDENTIFIED:"
puts "During hash processing, child answers are in a local 'result' hash,"
puts "not in @answers, so subsequent children can't access them via dig!"
puts "=" * 70

temp_file.unlink
