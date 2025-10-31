#!/usr/bin/env ruby
# Simple test to verify skip_if works in nested children

require_relative '../lib/prompter'
require 'tempfile'
require 'yaml'

puts "=" * 70
puts "Testing skip_if in nested children"
puts "=" * 70
puts

# Create a test schema
test_schema = {
  'enable_database' => {
    'type' => 'boolean',
    'prompt' => 'Enable database?',
    'default' => true
  },
  'database_config' => {
    'type' => 'hash',
    'prompt' => 'Database Configuration',
    'skip_if' => "->(answers) { answers['enable_database'] == false }",
    'children' => {
      'db_type' => {
        'type' => 'string',
        'prompt' => 'Database type',
        'default' => 'PostgreSQL'
      },
      'db_port' => {
        'type' => 'integer',
        'prompt' => 'Database port',
        'default' => 5432,
        'skip_if' => "->(answers) { answers['db_type'] == 'SQLite' }"
      },
      'db_file' => {
        'type' => 'string',
        'prompt' => 'Database file',
        'default' => 'db.sqlite3',
        'skip_if' => "->(answers) { answers['db_type'] != 'SQLite' }"
      }
    }
  }
}

# Create temporary schema file
temp_file = Tempfile.new(['schema', '.yml'])
temp_file.write(test_schema.to_yaml)
temp_file.close

runner = Prompter::Runner.new(temp_file.path)

puts "Test 1: skip_if logic for child field (PostgreSQL - should skip db_file)"
puts "-" * 70

# Test with PostgreSQL
runner.instance_variable_set(:@answers, {
  'enable_database' => true,
  'db_type' => 'PostgreSQL'
})

db_port_config = test_schema['database_config']['children']['db_port']
db_file_config = test_schema['database_config']['children']['db_file']

should_ask_port = runner.send(:should_ask?, db_port_config)
should_ask_file = runner.send(:should_ask?, db_file_config)

puts "Answers: db_type = 'PostgreSQL'"
puts "should_ask db_port? #{should_ask_port}"
puts "should_ask db_file? #{should_ask_file}"

test1_pass = should_ask_port == true && should_ask_file == false
puts test1_pass ? "[PASS] Test 1" : "[FAIL] Test 1"

puts "\n"
puts "Test 2: skip_if logic for child field (SQLite - should skip db_port)"
puts "-" * 70

# Test with SQLite
runner.instance_variable_set(:@answers, {
  'enable_database' => true,
  'db_type' => 'SQLite'
})

should_ask_port = runner.send(:should_ask?, db_port_config)
should_ask_file = runner.send(:should_ask?, db_file_config)

puts "Answers: db_type = 'SQLite'"
puts "should_ask db_port? #{should_ask_port}"
puts "should_ask db_file? #{should_ask_file}"

test2_pass = should_ask_port == false && should_ask_file == true
puts test2_pass ? "[PASS] Test 2" : "[FAIL] Test 2"

puts "\n"
puts "Test 3: skip_if for parent hash (enable_database = false)"
puts "-" * 70

runner.instance_variable_set(:@answers, {
  'enable_database' => false
})

parent_config = test_schema['database_config']
should_ask = runner.send(:should_ask?, parent_config)

puts "Answers: enable_database = false"
puts "should_ask database_config? #{should_ask}"

test3_pass = should_ask == false
puts test3_pass ? "[PASS] Test 3" : "[FAIL] Test 3"

puts "\n" + "=" * 70
if test1_pass && test2_pass && test3_pass
  puts "All tests PASSED!"
else
  puts "Some tests FAILED"
  exit 1
end
puts "=" * 70

temp_file.unlink
