#!/usr/bin/env ruby
# Test to verify nested answers with dig work correctly

require_relative '../lib/prompter'
require 'tempfile'
require 'yaml'

puts "=" * 70
puts "Testing nested dig with sibling dependencies"
puts "=" * 70
puts

# Schema matching user's scenario
test_schema = {
  'pre_checks' => {
    'type' => 'hash',
    'prompt' => 'Pre-checks',
    'children' => {
      'allow_destructive_prime' => {
        'type' => 'string',
        'prompt' => 'Allow destructive?',
        'default' => 'no'
      },
      # This child depends on previous sibling within same hash
      'confirm_destruction' => {
        'type' => 'string',
        'prompt' => 'Confirm destruction',
        'default' => 'no',
        'skip_if' => "->(answers) { !answers.dig('pre_checks', 'allow_destructive_prime') || answers.dig('pre_checks', 'allow_destructive_prime') == 'no' }"
      },
      'backup_done' => {
        'type' => 'string',
        'prompt' => 'Backup completed?',
        'default' => 'yes'
      }
    }
  },
  # This field depends on nested value from pre_checks hash
  'dangerous_operation' => {
    'type' => 'string',
    'prompt' => 'Dangerous operation',
    'default' => 'none',
    'skip_if' => "->(answers) { !answers.dig('pre_checks', 'allow_destructive_prime') || answers.dig('pre_checks', 'allow_destructive_prime') == 'no' }"
  }
}

temp_file = Tempfile.new(['schema', '.yml'])
temp_file.write(test_schema.to_yaml)
temp_file.close

puts "Test 1: Sibling dependency within hash (allow_destructive_prime = 'no')"
puts "-" * 70

runner1 = Prompter::Runner.new(temp_file.path)
pre_checks_config = test_schema['pre_checks']

# Manually trigger processing to simulate user flow
runner1.instance_variable_set(:@answers, {})

# Simulate processing first child
runner1.instance_variable_get(:@answers)['pre_checks'] = {}
runner1.instance_variable_get(:@answers)['pre_checks']['allow_destructive_prime'] = 'no'

confirm_config = pre_checks_config['children']['confirm_destruction']
should_ask_confirm = runner1.send(:should_ask?, confirm_config)

puts "After first child: allow_destructive_prime = 'no'"
puts "Answers: #{runner1.answers.inspect}"
puts "should_ask confirm_destruction? #{should_ask_confirm}"
puts "Expected: false (should skip)"

test1_pass = should_ask_confirm == false
puts test1_pass ? "[PASS] Test 1" : "[FAIL] Test 1"

puts "\n"
puts "Test 2: Sibling dependency within hash (allow_destructive_prime = 'yes')"
puts "-" * 70

runner2 = Prompter::Runner.new(temp_file.path)
runner2.instance_variable_set(:@answers, {})

# Simulate processing first child with 'yes'
runner2.instance_variable_get(:@answers)['pre_checks'] = {}
runner2.instance_variable_get(:@answers)['pre_checks']['allow_destructive_prime'] = 'yes'

should_ask_confirm = runner2.send(:should_ask?, confirm_config)

puts "After first child: allow_destructive_prime = 'yes'"
puts "Answers: #{runner2.answers.inspect}"
puts "should_ask confirm_destruction? #{should_ask_confirm}"
puts "Expected: true (should ask)"

test2_pass = should_ask_confirm == true
puts test2_pass ? "[PASS] Test 2" : "[FAIL] Test 2"

puts "\n"
puts "Test 3: Field depending on nested hash value"
puts "-" * 70

runner3 = Prompter::Runner.new(temp_file.path)
runner3.instance_variable_set(:@answers, {
  'pre_checks' => {
    'allow_destructive_prime' => 'no',
    'backup_done' => 'yes'
  }
})

dangerous_config = test_schema['dangerous_operation']
should_ask_dangerous = runner3.send(:should_ask?, dangerous_config)

puts "After pre_checks complete: allow_destructive_prime = 'no'"
puts "Answers: #{runner3.answers.inspect}"
puts "should_ask dangerous_operation? #{should_ask_dangerous}"
puts "Expected: false (should skip)"

test3_pass = should_ask_dangerous == false
puts test3_pass ? "[PASS] Test 3" : "[FAIL] Test 3"

puts "\n"
puts "Test 4: Field depending on nested hash value = 'yes'"
puts "-" * 70

runner4 = Prompter::Runner.new(temp_file.path)
runner4.instance_variable_set(:@answers, {
  'pre_checks' => {
    'allow_destructive_prime' => 'yes',
    'confirm_destruction' => 'yes',
    'backup_done' => 'yes'
  }
})

should_ask_dangerous = runner4.send(:should_ask?, dangerous_config)

puts "After pre_checks complete: allow_destructive_prime = 'yes'"
puts "Answers: #{runner4.answers.inspect}"
puts "should_ask dangerous_operation? #{should_ask_dangerous}"
puts "Expected: true (should ask)"

test4_pass = should_ask_dangerous == true
puts test4_pass ? "[PASS] Test 4" : "[FAIL] Test 4"

puts "\n" + "=" * 70
if test1_pass && test2_pass && test3_pass && test4_pass
  puts "All tests PASSED!"
  puts "Nested dig with sibling dependencies now works!"
else
  puts "Some tests FAILED"
  exit 1
end
puts "=" * 70

temp_file.unlink
