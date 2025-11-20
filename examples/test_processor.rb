#!/usr/bin/env ruby
# Test script to verify processor functionality works end-to-end

require_relative '../lib/prompter'
require_relative 'processors/feature_flag_processor'

# Create a simple test processor for quick testing
class SimpleProcessor
  def self.get_options(answers:, config:)
    puts "  [Processor called with answers: #{answers.keys.join(', ')}]"

    selected = answers[config['depends_on']]

    case selected
    when 'small'
      ['option_a', 'option_b']
    when 'medium'
      ['option_a', 'option_b', 'option_c']
    when 'large'
      ['option_a', 'option_b', 'option_c', 'option_d', 'option_e']
    else
      []
    end
  end
end

puts "=" * 60
puts "Testing Prompter Processor Feature"
puts "=" * 60
puts

# Test 1: Simple processor
puts "Test 1: Simple Processor Test"
puts "-" * 60

test_schema_1 = {
  'size' => {
    'type' => 'select',
    'prompt' => 'Select size',
    'options' => ['small', 'medium', 'large']
  },
  'options' => {
    'type' => 'multi_select',
    'prompt' => 'Select options (dynamically filtered by size)',
    'source' => {
      'type' => 'processor',
      'class' => 'SimpleProcessor',
      'method' => 'get_options',
      'depends_on' => 'size'
    }
  }
}

# Create a temporary schema file
require 'tempfile'
require 'yaml'
temp_file_1 = Tempfile.new(['schema', '.yml'])
temp_file_1.write(test_schema_1.to_yaml)
temp_file_1.close

runner1 = Prompter::Runner.new(temp_file_1.path)

# Simulate answers for automated testing
puts "\nSimulating user selecting 'medium' size..."
runner1.instance_variable_set(:@answers, {'size' => 'medium'})

# Test the processor directly
source_config = test_schema_1['options']['source']
options = runner1.send(:load_source, source_config)

puts "\nProcessor returned options: #{options.inspect}"

if options == ['option_a', 'option_b', 'option_c']
  puts "[PASS] Test 1 PASSED: Processor returned correct options for 'medium'"
else
  puts "[FAIL] Test 1 FAILED: Expected ['option_a', 'option_b', 'option_c'], got #{options.inspect}"
  exit 1
end

# Test 2: Feature flag processor
puts "\n\nTest 2: Feature Flag Processor Test"
puts "-" * 60

test_schema_2 = {
  'release_version' => {
    'type' => 'select',
    'prompt' => 'Select release version',
    'options' => ['3.1.5.1', '3.1.5.3', '3.2.0.0']
  },
  'feature_flags' => {
    'type' => 'multi_select',
    'prompt' => 'Select feature flags',
    'source' => {
      'type' => 'processor',
      'class' => 'FeatureFlagProcessor',
      'method' => 'filter_by_release',
      'data_file' => File.join(__dir__, 'features.yml')
    }
  }
}

temp_file_2 = Tempfile.new(['schema', '.yml'])
temp_file_2.write(test_schema_2.to_yaml)
temp_file_2.close

runner2 = Prompter::Runner.new(temp_file_2.path)

# Test case 1: Version 3.1.5.1
puts "\nTest case: Release version 3.1.5.1"
runner2.instance_variable_set(:@answers, {'release_version' => '3.1.5.1'})
source_config = test_schema_2['feature_flags']['source']
options = runner2.send(:load_source, source_config)

puts "Processor returned: #{options.inspect}"
expected = ['flag1', 'flag2', 'flag3', 'flag4']
if options.sort == expected.sort
  puts "[PASS] Test 2.1 PASSED: Correct flags for version 3.1.5.1"
else
  puts "[FAIL] Test 2.1 FAILED: Expected #{expected.inspect}, got #{options.inspect}"
end

# Test case 2: Version 3.1.5.3
puts "\nTest case: Release version 3.1.5.3"
runner2.instance_variable_set(:@answers, {'release_version' => '3.1.5.3'})
options = runner2.send(:load_source, source_config)

puts "Processor returned: #{options.inspect}"
expected = ['flag1', 'flag2', 'flag3', 'flag4', 'flag5', 'flag6', 'flag7', 'flag8']
if options.sort == expected.sort
  puts "[PASS] Test 2.2 PASSED: Correct flags for version 3.1.5.3"
else
  puts "[FAIL] Test 2.2 FAILED: Expected #{expected.inspect}, got #{options.inspect}"
end

# Test case 3: Version 3.2.0.0 (all flags)
puts "\nTest case: Release version 3.2.0.0"
runner2.instance_variable_set(:@answers, {'release_version' => '3.2.0.0'})
options = runner2.send(:load_source, source_config)

puts "Processor returned: #{options.inspect}"
expected = ['flag1', 'flag2', 'flag3', 'flag4', 'flag5', 'flag6', 'flag7', 'flag8']
if options.sort == expected.sort
  puts "[PASS] Test 2.3 PASSED: Correct flags for version 3.2.0.0"
else
  puts "[FAIL] Test 2.3 FAILED: Expected #{expected.inspect}, got #{options.inspect}"
end

# Test 3: Error handling
puts "\n\nTest 3: Error Handling"
puts "-" * 60

test_schema_3 = {
  'field' => {
    'type' => 'select',
    'prompt' => 'Test',
    'source' => {
      'type' => 'processor',
      'class' => 'NonExistentProcessor',
      'method' => 'some_method'
    }
  }
}

temp_file_3 = Tempfile.new(['schema', '.yml'])
temp_file_3.write(test_schema_3.to_yaml)
temp_file_3.close

runner3 = Prompter::Runner.new(temp_file_3.path)
runner3.instance_variable_set(:@answers, {})

source_config = test_schema_3['field']['source']
options = runner3.send(:load_source, source_config)

if options == []
  puts "[PASS] Test 3 PASSED: Gracefully handled missing processor class"
else
  puts "[FAIL] Test 3 FAILED: Should return empty array on error"
end

puts "\n" + "=" * 60
puts "All Tests Completed!"
puts "=" * 60
