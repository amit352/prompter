require "yaml"
require "tty-prompt"

module Prompter
  class Runner
    attr_reader :schema_path, :answers, :prompt

    def initialize(schema_path)
      @schema_path = schema_path
      @schema = YAML.load_file(schema_path)
      @prompt = TTY::Prompt.new
      @answers = {}
    end

    def run
      puts "Starting Prompter for: #{@schema_path}\n\n"
      puts "Press Ctrl+C at any time to exit\n\n"

      begin
        @schema.each do |key, config|
          next unless should_ask?(config)
          value = ask_question(key, config)
          @answers[key] = value unless value.nil?
        end

        puts "\n Final Answers:"
        @answers.each { |k, v| puts "  #{k}: #{v}" }

        @answers
      rescue Interrupt
        handle_interrupt
      end
    end

    private

    def handle_interrupt
      puts "\n\nInterrupted by user!"
      puts "\nCurrent answers:"
      @answers.each { |k, v| puts "  #{k}: #{v}" }

      choice = @prompt.select("\nWhat would you like to do?", [
        { name: "Save partial results and exit", value: :save },
        { name: "Exit without saving", value: :exit }
      ])

      if choice == :save
        puts "\nPartial results will be saved."
        @answers
      else
        puts "\nExiting without saving."
        exit(1)
      end
    rescue Interrupt
      puts "\n\nForce exit. No data saved."
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

    def ask_question(key, config)
      qtype = config["type"] || "string"
      prompt_text = config["prompt"] || key
      default = config["default"]
      options = config["options"] || config["choices"]
      help = config["help"]
      required = config["required"]
      source = config["source"]
      confirm = config["confirm"]
      validate = config["validate"]
      convert = config["convert"]
      transform = config["transform"]

      options ||= load_source(source)
      puts "#{help}" if help

      value =
        case qtype
        when "string"
          prompt.ask(prompt_text, default: default, required: required) do |q|
            apply_validation(q, validate)
          end
        when "integer"
          prompt.ask(prompt_text, convert: :int, default: default, required: required)
        when "boolean"
          prompt.yes?(prompt_text) { |q| q.default(default) }
        when "select"
          prompt.select(prompt_text, options, default: default)
        when "multi_select"
          prompt.multi_select(prompt_text, options, default: Array(default))
        when "hash"
          ask_hash(prompt_text, config["children"])
        else
          prompt.ask(prompt_text, default: default)
        end

      # Transform
      if transform
        begin
          fn = eval(transform)
          value = fn.call(value)
        rescue StandardError
          # ignore transform errors
        end
      end

      # Convert
      case convert
      when "int" then value = value.to_i
      when "float" then value = value.to_f
      end

      # Confirm
      if confirm && !prompt.yes?("Confirm '#{value}'?")
        return ask_question(key, config)
      end

      value
    end

    def ask_hash(prompt_text, children)
      puts "\n#{prompt_text}:"
      result = {}
      children.each do |k, v|
        next unless should_ask?(v)
        val = ask_question(k, v)
        result[k] = val unless val.nil?
      end
      result
    end

    def load_source(source)
      return unless source
      type = source["type"]
      path = source["path"]

      case type
      when "files"
        Dir.children(path).select { |f| File.file?(File.join(path, f)) }
      when "yaml"
        yaml_data = YAML.load_file(path)
        yaml_data.is_a?(Hash) ? yaml_data.keys : yaml_data
      when "proc"
        fn = eval(source["proc"])
        fn.call
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
      class_name = source["class"]
      method_name = source["method"]

      raise "Processor class name is required" unless class_name
      raise "Processor method name is required" unless method_name

      # Get the processor class
      processor_class = Object.const_get(class_name)

      # Prepare config hash (all source params except type, class, method)
      config = source.reject { |k, _| ["type", "class", "method"].include?(k) }

      # Call the processor method with answers and config
      processor_class.public_send(method_name, answers: @answers, config: config)
    rescue NameError => e
      puts "Processor class '#{class_name}' not found. Make sure it's defined and loaded."
      puts "Error: #{e.message}"
      []
    rescue NoMethodError => e
      puts "Method '#{method_name}' not found on #{class_name}."
      puts "Error: #{e.message}"
      []
    rescue StandardError => e
      puts "Processor error: #{e.message}"
      puts e.backtrace.first(3).join("\n  ")
      []
    end

    def apply_validation(question, rule)
      return unless rule
      if rule.is_a?(String) && rule.start_with?("/")
        regex = Regexp.new(rule[1..-2])
        question.validate(->(input) { input.match?(regex) }, "Invalid format")
      elsif rule.is_a?(String) && rule.start_with?("->")
        fn = eval(rule)
        question.validate(fn, "Invalid input")
      end
    rescue StandardError => e
      puts "Validation setup error: #{e.message}"
      nil
    end
  end
end
