lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "chef-licensing/version"

Gem::Specification.new do |spec|
  spec.name          = "chef-licensing"
  spec.version       = ChefLicensing::VERSION
  spec.authors       = ["Inspec Team"]
  spec.email         = ["inspec@progress.com"]
  spec.license       = "Apache-2.0"

  spec.summary       = %q{Chef License storage, generation, and entitlement}
  spec.description   = %q{Ruby library to support CLI tools that use Progress Chef license storage, generation, and entitlement.}
  spec.homepage      = "https://github.com/chef/chef-licensing"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/chef/chef-licensing"

  # Specify which files should be added to the gem when it is released.
  spec.files =
  Dir.glob("{{lib,etc}/**/*,LICENSE,chef-licensing.gemspec}")
    .reject { |f| File.directory?(f) }

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "chef-config", ">= 15"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "faraday", ">= 1", "< 3"
  spec.add_dependency "faraday-http-cache"
  # Note: 7.1.0 does not defaults its cache_format_version to 7.1 but 6.1 instead which gives deprecation warnings
  # Remove the version constraint when we can upgrade to 7.1.1 post stable release of Activesupport 7.1
  # Similar issue with 7.0 existed: https://github.com/rails/rails/pull/45293
  spec.add_dependency "activesupport", "~> 7.0", "< 7.1"
  spec.add_dependency "tty-spinner", "~> 0.9.3"
end
