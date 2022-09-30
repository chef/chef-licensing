lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef_licensing/version"

Gem::Specification.new do |spec|
  spec.name          = "chef_licensing"
  spec.version       = ChefLicensing::VERSION
  spec.authors       = ["Inspec Team"]
  spec.email         = ["inspec@progress.com"]
  spec.license       = "Proprietary"

  spec.summary       = %q{Chef License storage, generation, and entitlement}
  spec.description   = %q{Ruby library to support CLI tools that use Progress Chef license storage, generation, and entitlement.}
  spec.homepage      = "https://github.com/chef/chef-licensing"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/chef/chef-licensing"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    "git ls-files -z".split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "chef-config", ">= 15"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "faraday", "~> 2.5", ">= 2.5.2"
end
