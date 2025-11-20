# Example processor for filtering feature flags based on release version
#
# This demonstrates how to create a custom processor that dynamically
# generates options based on user's previous answers.
#
# Usage in schema:
#   feature_flags:
#     type: multi_select
#     prompt: "Select feature flags"
#     source:
#       type: "processor"
#       class: "FeatureFlagProcessor"
#       method: "filter_by_release"
#       data_file: "features.yml"

class FeatureFlagProcessor
  # Filters feature flags based on the selected release version
  #
  # @param answers [Hash] Hash containing all previous user answers
  # @param config [Hash] Configuration passed from the schema
  # @return [Array<String>] List of available feature flags
  def self.filter_by_release(answers:, config:)
    require 'yaml'

    # Load feature flags data
    data_file = config['data_file'] || 'features.yml'
    features = YAML.load_file(data_file)

    # Get the release version from previous answers
    release_version = answers['release_version']
    return [] unless release_version

    # Define which versions to include for each release
    version_mapping = {
      '3.1.5.1' => ['3.1.5.0', '3.1.5.1'],
      '3.1.5.3' => ['3.1.5.0', '3.1.5.1', '3.1.5.2', '3.1.5.3'],
      '3.2.0.0' => :all  # Include all flags
    }

    versions_to_include = version_mapping[release_version]

    # Handle different version scenarios
    if versions_to_include == :all
      # For version 3.2.0.0, include all available flags
      all_flags = []
      features['feature_flags']['releases'].each do |_version, flags|
        all_flags.concat(flags)
      end
      all_flags.uniq
    elsif versions_to_include
      # Include flags from specified versions
      flags = []
      versions_to_include.each do |version|
        version_flags = features['feature_flags']['releases'][version]
        flags.concat(version_flags) if version_flags
      end
      flags.uniq
    else
      # Unknown version
      []
    end
  rescue StandardError => e
    puts "Error loading feature flags: #{e.message}"
    []
  end
end
