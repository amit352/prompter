require_relative "lib/prompter/version"

Gem::Specification.new do |spec|
  spec.name          = "prompter"
  spec.version       = Prompter::VERSION
  spec.authors       = ["Amit Kumar"]
  spec.email         = ["kumar352@gmail.com"]

  spec.summary       = "Interactive YAML-driven config prompter"
  spec.description   = "Prompter reads a YAML schema and interactively prompts users to generate validated configuration files."
  spec.homepage      = "https://github.com/amit352/prompter"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md", "SCHEMA_GUIDE.md", "QUICK_REFERENCE.md", "examples/**/*"]
  spec.executables   = ["prompter"]
  spec.require_paths = ["lib"]

  spec.add_dependency "tty-prompt"
  spec.add_dependency "psych"
end
