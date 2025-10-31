#!/usr/bin/env ruby
# Test to verify nested answers are accessible via dig

require_relative '../lib/prompter'
require 'tempfile'
require 'yaml'

puts "=" * 70
puts "Testing nested answers with dig"
puts "=" * 70
puts

# Schema similar to user's issue
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
      'backup_completed' => {
        'type' => 'boolean',
        'prompt' => 'Backup completed?',
        'default' => false
      }
    }
  },
  'dangerous_operation' => {
    'type' => 'string',
    'prompt' => 'Dangerous operation',
    'default' => 'none',
    'skip_if' => "->(answers) { !answers.dig('pre_checks', 'allow_destructive_prime') }"
  }
}

# Create temporary schema file
temp_file = Tempfile.new(['schema', '.yml'])
temp_file.write(test_schema.to_yaml)
temp_file.close

runner = Prompter::Runner.new(temp_file.path)

puts "Test: skip_if with nested dig access"
puts "-" * 70

# Simulate pre_checks being answered
runner.instance_variable_set(:@answers, {
  'pre_checks' => {
    'allow_destructive_prime' => false,
    'backup_completed' => true
  }
})

dangerous_op_config = test_schema['dangerous_operation']
should_ask = runner.send(:should_ask?, dangerous_op_config)

puts "Answers: pre_checks.allow_destructive_prime = false"
puts "should_ask dangerous_operation? #{should_ask}"
puts "Expected: false (should be skipped)"

test1_pass = should_ask == false
puts test1_pass ? "[PASS] Test 1: Skip when false" : "[FAIL] Test 1: Skip when false"

puts "\n"

# Test 2: Should ask when true
runner.instance_variable_set(:@answers, {
  'pre_checks' => {
    'allow_destructive_prime' => true,
    'backup_completed' => true
  }
})

should_ask = runner.send(:should_ask?, dangerous_op_config)

puts "Answers: pre_checks.allow_destructive_prime = true"
puts "should_ask dangerous_operation? #{should_ask}"
puts "Expected: true (should be asked)"

test2_pass = should_ask == true
puts test2_pass ? "[PASS] Test 2: Ask when true" : "[FAIL] Test 2: Ask when true"

puts "\n" + "=" * 70
if test1_pass && test2_pass
  puts "All tests PASSED!"
else
  puts "Some tests FAILED"
  puts "\nThis is the issue - when processing hash children, answers are not"
  puts "accessible via dig until the hash is fully processed and stored."
end
puts "=" * 70

temp_file.unlink
