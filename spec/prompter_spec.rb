# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Prompter do
  # Reset configuration after each test
  after do
    described_class.reset_configuration!
  end

  describe '.configuration' do
    it 'returns a Configuration instance' do
      expect(described_class.configuration).to be_a(Prompter::Configuration)
    end

    it 'returns the same instance on multiple calls' do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe '.configure' do
    it 'yields the configuration object' do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Prompter::Configuration)
    end

    it 'allows setting schema_path' do
      described_class.configure do |config|
        config.schema_path = 'test/schema.yml'
      end
      expect(described_class.configuration.schema_path).to eq('test/schema.yml')
    end

    it 'allows setting output_path' do
      described_class.configure do |config|
        config.output_path = 'test/output.yml'
      end
      expect(described_class.configuration.output_path).to eq('test/output.yml')
    end

    it 'allows setting both paths' do
      described_class.configure do |config|
        config.schema_path = 'test/schema.yml'
        config.output_path = 'test/output.yml'
      end
      expect(described_class.configuration.schema_path).to eq('test/schema.yml')
      expect(described_class.configuration.output_path).to eq('test/output.yml')
    end
  end

  describe '.reset_configuration!' do
    it 'resets the configuration to defaults' do
      described_class.configure do |config|
        config.schema_path = 'test/schema.yml'
        config.output_path = 'test/output.yml'
      end

      described_class.reset_configuration!

      expect(described_class.configuration.schema_path).to be_nil
      expect(described_class.configuration.output_path).to be_nil
    end

    it 'creates a new configuration instance' do
      old_config = described_class.configuration
      described_class.reset_configuration!
      new_config = described_class.configuration
      expect(new_config).not_to be(old_config)
    end
  end

  describe '.run' do
    let(:schema_file) do
      Tempfile.new(['schema', '.yml']).tap do |f|
        f.write(YAML.dump({
          'name' => {
            'type' => 'string',
            'prompt' => 'Name?',
            'default' => 'test'
          }
        }))
        f.rewind
      end
    end

    let(:output_file) { Tempfile.new(['output', '.yml']) }

    after do
      schema_file.close
      schema_file.unlink
      output_file.close
      output_file.unlink
    end

    context 'without configuration' do
      it 'raises ArgumentError when no schema_path is provided' do
        expect {
          described_class.run
        }.to raise_error(ArgumentError, 'schema_path must be provided or configured')
      end

      it 'accepts explicit schema_path' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test' })

        expect {
          described_class.run(schema_file.path)
        }.not_to raise_error
      end

      it 'accepts explicit schema_path and output_path' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test' })

        expect {
          described_class.run(schema_file.path, output_file.path)
        }.not_to raise_error
      end
    end

    context 'with configured paths' do
      before do
        described_class.configure do |config|
          config.schema_path = schema_file.path
          config.output_path = output_file.path
        end
      end

      it 'uses configured schema_path when not provided' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test' })

        expect(Prompter::Runner).to receive(:new).with(schema_file.path).and_call_original
        described_class.run
      end

      it 'uses configured output_path when not provided' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test' })

        described_class.run
        expect(File.exist?(output_file.path)).to be true
      end

      it 'overrides configured schema_path with explicit parameter' do
        custom_schema = Tempfile.new(['custom', '.yml'])
        custom_schema.write(YAML.dump({ 'test' => { 'type' => 'string', 'prompt' => 'Test?', 'default' => 'val' } }))
        custom_schema.rewind

        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'test' => 'val' })

        expect(Prompter::Runner).to receive(:new).with(custom_schema.path).and_call_original
        described_class.run(custom_schema.path)

        custom_schema.close
        custom_schema.unlink
      end

      it 'overrides configured output_path with explicit parameter' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test' })

        custom_output = Tempfile.new(['custom_output', '.yml'])
        described_class.run(nil, custom_output.path)

        expect(File.exist?(custom_output.path)).to be true
        custom_output.close
        custom_output.unlink
      end

      it 'returns the answers hash' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test_value' })

        result = described_class.run
        expect(result).to eq({ 'name' => 'test_value' })
      end
    end

    context 'with only schema_path configured' do
      before do
        described_class.configure do |config|
          config.schema_path = schema_file.path
        end
      end

      it 'runs without saving to file' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test' })

        result = described_class.run
        expect(result).to eq({ 'name' => 'test' })
      end

      it 'saves to file when output_path is provided explicitly' do
        allow_any_instance_of(Prompter::Runner).to receive(:run).and_return({ 'name' => 'test' })

        described_class.run(nil, output_file.path)
        expect(File.exist?(output_file.path)).to be true
      end
    end
  end
end
