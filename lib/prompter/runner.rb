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
      puts "🧾 Starting Prompter for: #{@schema_path}\n\n"
      @schema.each do |key, config|
        next unless should_ask?(config)
        value = ask_question(key, config)
        @answers[key] = value unless value.nil?
      end

      puts "\n Final Answers:"
      @answers.each { |k, v| puts "  #{k}: #{v}" }

      @answers
    end

    private

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
      options = config["options"]
      help = config["help"]
      required = config["required"]
      source = config["source"]
      confirm = config["confirm"]
      validate = config["validate"]
      convert = config["convert"]
      transform = config["transform"]

      options ||= load_source(source)
      puts "💡 #{help}" if help

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
      else
        []
      end
    rescue StandardError => e
      puts "⚠️  Source load error: #{e.message}"
      []
    end

    def apply_validation(question, rule)
      return unless rule
      if rule.is_a?(String) && rule.start_with?("/")
        regex = Regexp.new(rule[1..-2])
        question.validate(regex)
      elsif rule.start_with?("->")
        fn = eval(rule)
        question.validate("Invalid input", &fn)
      end
    rescue StandardError
      nil
    end
  end
end
