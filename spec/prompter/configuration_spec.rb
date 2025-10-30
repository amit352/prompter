# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prompter::Configuration do
  subject(:config) { described_class.new }

  describe '#initialize' do
    it 'initializes with nil schema_path' do
      expect(config.schema_path).to be_nil
    end

    it 'initializes with nil output_path' do
      expect(config.output_path).to be_nil
    end
  end

  describe '#schema_path=' do
    it 'allows setting schema_path' do
      config.schema_path = 'path/to/schema.yml'
      expect(config.schema_path).to eq('path/to/schema.yml')
    end
  end

  describe '#output_path=' do
    it 'allows setting output_path' do
      config.output_path = 'path/to/output.yml'
      expect(config.output_path).to eq('path/to/output.yml')
    end
  end

  describe '#reset!' do
    it 'resets schema_path to nil' do
      config.schema_path = 'path/to/schema.yml'
      config.reset!
      expect(config.schema_path).to be_nil
    end

    it 'resets output_path to nil' do
      config.output_path = 'path/to/output.yml'
      config.reset!
      expect(config.output_path).to be_nil
    end
  end
end
