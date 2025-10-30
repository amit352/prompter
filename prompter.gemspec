Gem::Specification.new do |spec|
  spec.name          = "prompter"
  spec.version       = "0.1.0"
  spec.authors       = ["Amit Kumar"]
  spec.email         = ["kumar352@gmail.com", "amit.chauhan@sycamoreinformatics.com"]

  spec.summary       = "Interactive YAML-driven config prompter"
  spec.description   = "Prompter reads a YAML schema and interactively prompts users to generate validated configuration files."
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "bin/*", "README.md"]
  spec.executables   = ["prompter"]
  spec.require_paths = ["lib"]

  spec.add_dependency "tty-prompt"
  spec.add_dependency "psych"
end
