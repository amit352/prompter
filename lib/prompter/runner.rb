require "yaml"
require "tty-prompt"

module Prompter
  class Runner
    attr_reader :schema_path, :answers, :prompt

    def initialize(schema_path, debug: false)
      @schema_path = schema_path
      @schema = YAML.load_file(schema_path)
      @prompt = TTY::Prompt.new
      @answers = {}
      @debug = debug
    end

    def run
      puts "Starting Prompter for: #{@schema_path}"
      puts "Press Ctrl+C at any time to exit"

      # Pre-generate the full structure
      generate_structure(@schema, @answers)

      begin
        traverse_schema(@schema, @answers)
        puts "\nFinal Answers:"
        pp @answers if @debug
        @answers
      rescue Interrupt
        handle_interrupt
      end
    end

    private

    # Recursively generate hash/array structure with defaults
    def generate_structure(schema, container)
      schema.each do |key, config|
        case config["type"]
        when "hash"
          container[key] = {}
          generate_structure(config["children"] || {}, container[key])
        when "array"
          length = config["length"]
          if length.is_a?(String) && length.start_with?("->")
            length = 0 # dynamic length; will fill during prompt
          else
            length = length.to_i
          end
          children = config["children"] || {}
          container[key] = Array.new(length) { {}.tap { |h| generate_structure(children, h) } }
        else
          container[key] = config.key?("default") ? config["default"] : nil
        end
      end
    end

    # Traverse schema and prompt
    def traverse_schema(schema, container)
      schema.each do |key, config|
        next unless should_ask?(config)
        ask_question(key, config, container)
      end
    end

    def handle_interrupt
      puts "\nInterrupted by user!"
      debug_print_full_answers if @debug

      choice = @prompt.select("What would you like to do?", [
        { name: "Save partial results and exit", value: :save },
        { name: "Exit without saving", value: :exit }
      ])

      if choice == :save
        puts "Partial results will be saved."
        @answers
      else
        puts "Exiting without saving."
        exit(1)
      end
    rescue Interrupt
      puts "Force exit. No data saved."
      exit(1)
    end

    def should_ask?(config)
      skip_if = config["skip_if"]
      return true unless skip_if

      begin
        fn = eval(skip_if)
        !fn.call(@answers)
      rescue StandardError
        true
      end
    end

    def decorated_prompt_text(prompt_text, default)
      default ? "#{prompt_text} (default: #{default})" : prompt_text
    end

    def debug_print_full_answers(override = false)
      return unless @debug || override
      puts "[DEBUG] Current Answers: #{@answers}\n"
    end

    # Core prompting method
    def ask_question(key, config, container)
      qtype       = config["type"] || "string"
      prompt_text = decorated_prompt_text(config["prompt"] || key, config["default"])
      default     = config["default"]
      options     = config["options"] || config["choices"]
      help        = config["help"]
      required    = config["required"]
      source      = config["source"]
      confirm     = config["confirm"]
      validate    = config["validate"]
      convert     = config["convert"]
      transform   = config["transform"]

      options ||= load_source(source)
      puts help if help

      value =
        case qtype
        when "hash"
          ask_hash(key, prompt_text, config["children"], container)
        when "array"
          ask_array(key, prompt_text, config, container)
        when "string"
          @prompt.ask(prompt_text, default: default, required: required) { |q| apply_validation(q, validate) }
        when "integer"
          @prompt.ask(prompt_text, convert: :int, default: default, required: required)
        when "boolean"
          @prompt.yes?(prompt_text) { |q| q.default(default) }
        when "select"
          @prompt.select(prompt_text, options, default: default)
        when "multi_select"
          @prompt.multi_select(prompt_text, options, default: Array(default))
        else
          @prompt.ask(prompt_text, default: default)
        end

      # Transform & convert
      value = eval(transform).call(value) if transform
      value = value.to_i if convert == "int"
      value = value.to_f if convert == "float"

      # Confirm
      value = ask_question(key, config, container) if confirm && !@prompt.yes?("Confirm '#{value}'?")

      # Assign directly to the current container
      container[key] = value

      debug_print_full_answers
      value
    end

    def ask_hash(key, prompt_text, children, container)
      puts "\n#{prompt_text}:"
      hash_container = container[key] ||= {}

      children.each do |child_key, child_config|
        next unless should_ask?(child_config)
        ask_question(child_key, child_config, hash_container)
      end

      hash_container
    end

    def ask_array(key, prompt_text, config, container)
      puts "\n#{prompt_text}:"

      # Determine length dynamically if specified as a proc/lambda string
      length = config["length"]
      if length.is_a?(String) && length.start_with?("->")
        begin
          length = eval(length).call(@answers)
        rescue StandardError => e
          puts "Error evaluating array length for '#{key}': #{e.message}"
          length = 0
        end
      end
      length = length.to_i
      return [] if length <= 0

      children = config["children"] || {}
      results = []

      length.times do |index|
        puts "\n--- Entry #{index + 1} of #{length} ---"
        entry_container = {}

        # Treat every child as a Prompter config, same as hash
        children.each do |child_key, child_config|
          next unless should_ask?(child_config)
          ask_question(child_key, child_config, entry_container)
        end

        results << entry_container
      end

      container[key] = results
      results
    end

    def load_source(source)
      return unless source
      case source["type"]
      when "files"
        Dir.children(source["path"]).select { |f| File.file?(File.join(source["path"], f)) }
      when "yaml"
        yaml_data = YAML.load_file(source["path"])
        yaml_data.is_a?(Hash) ? yaml_data.keys : yaml_data
      when "proc"
        eval(source["proc"]).call
      when "processor"
        load_from_processor(source)
      else
        []
      end
    rescue StandardError => e
      puts "Source load error: #{e.message}"
      []
    end

    def load_from_processor(source)
      class_name  = source["class"]
      method_name = source["method"]
      processor_class = Object.const_get(class_name)
      config = source.reject { |k,_| ["type","class","method"].include?(k) }
      processor_class.public_send(method_name, answers: @answers, config: config)
    rescue NameError, NoMethodError, StandardError => e
      puts "Processor error: #{e.message}"
      []
    end

    def apply_validation(question, rule)
      return unless rule
      if rule.start_with?("/")
        regex = Regexp.new(rule[1..-2])
        question.validate(->(input){ input.match?(regex) }, "Invalid format")
      elsif rule.start_with?("->")
        fn = eval(rule)
        question.validate(fn, "Invalid input")
      end
    rescue StandardError => e
      puts "Validation setup error: #{e.message}"
    end
  end
end
