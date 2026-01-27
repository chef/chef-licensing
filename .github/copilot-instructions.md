# Chef Licensing Repository - Copilot Instructions

## Project Overview

This repository contains the Chef Licensing library - a multi-language licensing management system for Progress Chef products. It provides license storage, generation, validation, and entitlement checking capabilities for Chef CLI tools and applications.

### Purpose
- Manage license key validation and entitlements for Chef products
- Support both global licensing service (cloud-based) and local/on-premises licensing
- Provide a consistent licensing experience across Ruby and Go implementations
- Handle license types: Free Tier, Trial, and Commercial
- Track license expiration, exhaustion, and grace periods

## Repository Structure

```
chef-licensing/
├── components/
│   ├── ruby/          # Ruby implementation of Chef Licensing
│   └── go/            # Go implementation of Chef Licensing
├── .github/
│   └── workflows/     # CI/CD workflows for linting and testing
└── README.md
```

## Language Support

This is a **multi-language monorepo** with parallel implementations in Ruby and Go.

### Ruby Component (`components/ruby/`)

**Technology Stack:**
- Ruby >= 3.1.0 (Target: 3.4)
- RSpec for testing
- Cookstyle (ChefStyle variant of RuboCop) for linting
- Bundler for dependency management

**Key Dependencies:**
- `chef-config` >= 15 - Chef configuration utilities
- `tty-prompt` ~> 0.23 - Interactive terminal prompts
- `tty-spinner` ~> 0.9.3 - Terminal spinners for loading states
- `faraday` >= 1, < 3 - HTTP client
- `faraday-http-cache` - HTTP caching layer
- `mixlib-log` ~> 3.0 - Logging framework
- `ostruct` ~> 0.6.0 - OpenStruct support (Ruby 3.4+)
- `pstore` ~> 0.1.1 - File-based storage

**Core Architecture:**
```
lib/chef-licensing/
├── chef-licensing.rb           # Main entry point
├── config.rb                   # Configuration management
├── context.rb                  # Context handling for license service detection
├── license.rb                  # License data model
├── license_key_fetcher.rb      # License key retrieval and persistence
├── license_key_validator.rb    # License key validation
├── list_license_keys.rb        # Display license information
├── api/                        # API client implementations
│   ├── client.rb              # License client API
│   ├── describe.rb            # License description API
│   └── parser/                # Response parsers
├── cli_flags/                  # CLI argument parsing
├── config_fetcher/             # Configuration from args/env
│   ├── arg_fetcher.rb
│   └── env_fetcher.rb
├── exceptions/                 # Custom exception classes
├── license_key_fetcher/        # License fetching strategies
│   ├── base.rb
│   ├── file.rb                # File-based persistence
│   └── prompt.rb              # Interactive prompts
├── licensing_service/          # License service detection
│   └── local.rb               # Local licensing service
├── restful_client/             # HTTP client wrappers
│   ├── base.rb
│   └── v1.rb                  # V1 API endpoints
└── tui_engine/                 # Terminal UI engine
    ├── tui_actions.rb
    ├── tui_engine.rb
    ├── tui_interaction.rb
    └── tui_prompt.rb
```

**Key Ruby Classes & Modules:**
- `ChefLicensing` - Main module with public API methods
- `ChefLicensing::Config` - Singleton configuration class
- `ChefLicensing::License` - License data model with entitlements
- `ChefLicensing::LicenseKeyFetcher` - Orchestrates license key retrieval
- `ChefLicensing::Api::Client` - Client API for license validation
- `ChefLicensing::RestfulClient::V1` - RESTful API v1 client
- `ChefLicensing::Context` - Detects licensing service type (local vs global)

**Public Ruby API Methods:**
```ruby
# Configuration
ChefLicensing.configure { |config| ... }

# License operations
ChefLicensing.fetch_and_persist         # Fetch and save license keys
ChefLicensing.fetch_only                # Fetch without persisting
ChefLicensing.license_keys              # Get current license keys

# Entitlement checks
ChefLicensing.check_software_entitlement!
ChefLicensing.check_feature_entitlement!(feature_name:, feature_id:)

# Display license information
ChefLicensing.list_license_keys_info(opts)

# License enforcement control
ChefLicensing::Config.require_license_for { ... }
```

### Go Component (`components/go/`)

**Technology Stack:**
- Go 1.21.5+
- Standard testing package for unit tests
- golangci-lint for code quality (configured in workflow)

**Key Dependencies:**
- `github.com/cqroot/prompt` v0.9.3 - Interactive prompts
- `github.com/gookit/color` v1.5.4 - Terminal colors
- `github.com/theckman/yacspin` v0.13.12 - Spinner animations
- `gopkg.in/yaml.v2` v2.4.0 - YAML parsing
- `golang.org/x/term` v0.22.0 - Terminal handling

**Core Architecture:**
```
pkg/
├── chef_licensing.go           # Main public API
├── api/                        # API client implementations
│   ├── api_client.go          # HTTP client
│   ├── client.go              # License client API
│   ├── validate.go            # Validation endpoint
│   ├── describe.go            # Description endpoint
│   ├── list_licenses.go       # List licenses endpoint
│   ├── feature_entitlement.go # Feature entitlements
│   └── software_entitlement.go # Software entitlements
├── config/
│   └── config.go              # Configuration struct
├── key_fetcher/                # License key retrieval
│   ├── key_fetcher.go         # Core key fetching logic
│   ├── license_key_fetcher.go # Main fetcher implementation
│   ├── file_fetcher.go        # File operations
│   ├── file_handler.go        # File handler interface
│   ├── list_keys.go           # Display license keys
│   ├── prompt.go              # Interactive prompts
│   ├── prompt_config.go       # Prompt configuration
│   ├── action.go              # TUI actions
│   ├── conditions.go          # Conditional logic
│   └── interactions.yml       # TUI interaction flows
└── spinner/
    └── spinner.go             # Terminal spinner
```

**Key Go Types:**
- `cheflicensing.FetchAndPersist()` - Main entry point
- `cheflicensing.CheckSoftwareEntitlement()` - Entitlement check
- `config.LicenseConfig` - Configuration struct
- `api.APIClient` - HTTP API client
- `api.LicenseClient` - License client data model
- `keyfetcher` package - License key fetching logic

**Public Go API:**
```go
// Configuration
config.SetConfig(name, entitlementID, URL, executable string)
config.GetConfig() *LicenseConfig

// Main operations
cheflicensing.FetchAndPersist() []string
cheflicensing.CheckSoftwareEntitlement() (bool, error)

// Low-level API
api.GetClient() *APIClient
client.ValidateLicenseAPI(key string, options ...bool) (bool, error)
```

**Go License Client Methods:**
```go
// Status checks
(client LicenseClient) IsActive() bool
(client LicenseClient) IsExpired() bool
(client LicenseClient) IsExhausted() bool
(client LicenseClient) HaveGrace() bool

// Type checks
(client LicenseClient) IsTrial() bool
(client LicenseClient) IsFree() bool
(client LicenseClient) IsCommercial() bool

// Date utilities
(client LicenseClient) LicenseExpirationDate() time.Time
(client LicenseClient) ExpirationInDays() int
```

## Core Concepts

### License Types
1. **Free Tier** - Limited usage, free licenses
2. **Trial** - Time-limited evaluation licenses
3. **Commercial** - Paid licenses with full entitlements

### License States
- **Active** - Valid and operational
- **Expired** - Past expiration date
- **Exhausted** - Usage limit reached
- **Grace** - Grace period after expiration

### Licensing Service Types
1. **Global Licensing Service** - Cloud-based (default)
   - License keys stored in local file (`~/.chef/licenses.yaml`)
   - Validates against remote licensing server
   - Supports adding/generating licenses interactively

2. **Local/On-Premises Licensing Service** - Air-gapped
   - License keys fetched from local API
   - No option to add licenses locally
   - Detected via `ChefLicensing::Context.local_licensing_service?`

### Configuration Methods
Configuration can be set via:
1. **Direct configuration** (in code)
2. **Environment variables**: `CHEF_LICENSE_SERVER`, `CHEF_PRODUCT_NAME`, etc.
3. **CLI arguments**: `--chef-license-server`, `--chef-license-key`, etc.

### License Key Formats
Validated via regex patterns:
- **License Key**: `^([a-z]{4}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}-[0-9]{1,4})$`
- **Serial Key**: `^([A-Z0-9]{26})$`
- **Commercial Key**: `^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$`

### TUI Engine (Terminal User Interface)
- YAML-based interaction flows (`interactions.yml`)
- Supports prompts, selections, timeouts, and warnings
- Path-based navigation through licensing workflows
- Dynamic value interpolation (e.g., `{{.ProductName}}`)

## Development Standards

### Ruby Standards
- **Target Ruby Version**: 3.4
- **Linter**: Cookstyle with ChefStyle cops
- **Testing Framework**: RSpec
- **Style Guide**: Follow ChefStyle conventions
- **Test Location**: `spec/` directory with `_spec.rb` suffix
- **Mock/Stub**: Use WebMock for HTTP mocking

**Ruby Code Conventions:**
```ruby
# Use ChefStyle formatting
# Prefer explicit return values
# Use keyword arguments for clarity
# Document public API methods with @example and @note
# Use require_relative for internal requires
```

### Go Standards
- **Target Go Version**: 1.21.5+
- **Linter**: golangci-lint (latest version from go.mod)
- **Testing Framework**: Standard Go testing package
- **Test Location**: `*_test.go` files alongside source
- **Package Organization**: One package per directory

**Go Code Conventions:**
```go
// Follow standard Go formatting (gofmt)
// Use idiomatic Go patterns
// Export types/functions with capital letters
// Document exported symbols
// Prefer table-driven tests
// Use meaningful error messages
```

### Testing Standards

**Ruby Testing:**
```ruby
# spec/example_spec.rb
require "spec_helper"

RSpec.describe ChefLicensing::SomeClass do
  describe "#some_method" do
    it "does something" do
      expect(subject.some_method).to eq(expected_value)
    end
  end
end
```

**Go Testing:**
```go
// example_test.go
func TestSomeFunction(t *testing.T) {
    tests := []struct {
        name     string
        input    string
        expected bool
    }{
        {"case1", "input1", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := SomeFunction(tt.input)
            if got != tt.expected {
                t.Errorf("got %v, want %v", got, tt.expected)
            }
        })
    }
}
```

## CI/CD Workflow

The `.github/workflows/lint.yml` workflow runs:

1. **Markdown Linting** - `markdownlint-cli2-action`
2. **YAML Linting** - `yamllint`
3. **JSON Linting** - `demjson3`
4. **Ruby Linting** - Cookstyle with ChefStyle
5. **Go Linting** - golangci-lint
6. **Ruby Tests** - RSpec
7. **Go Tests** - `go test`

**Workflow triggers:**
- Push to `main` branch (paths: `components/**`, `.github/workflows/**`)
- Pull requests to `main`
- Manual dispatch

**Concurrency**: Only one workflow per ref runs at a time

## API Endpoints

### License Server V1 API
Base URL: `{license_server_url}/v1/`

**Endpoints:**
- `GET /v1/validate?licenseId={key}` - Validate a license key
- `GET /v1/client?license_keys={keys}&entitlement_id={id}` - Get client license info
- `GET /v1/desc?licenseId={key}&entitlementId={id}` - Describe license details
- `GET /v1/listLicenses?licenseId={key}&entitlementId={id}` - List all licenses

## Error Handling

### Ruby Exceptions
```ruby
ChefLicensing::Error                    # Base error
ChefLicensing::ClientError              # API client errors
ChefLicensing::SoftwareNotEntitled      # Software not entitled
ChefLicensing::FeatureNotEntitled       # Feature not entitled
ChefLicensing::InvalidLicense           # Invalid license key
ChefLicensing::LicenseKeyNotFetchedError # Cannot obtain license key
```

### Go Error Handling
```go
// Return errors, don't panic
// Use log.Fatal only in main or critical paths
// Wrap errors with context
// Check errors explicitly
```

## File Storage

### License File Location
**Ruby**: `~/.chef/licenses.yaml` (via `ChefConfig::PathHelper`)
**Go**: `~/.chef/licenses.yaml` (hardcoded path)

### File Format (YAML)
```yaml
---
license_server_url: "https://licensing-acceptance.chef.co/License"
licenses:
  - product_name: "Workstation"
    license_keys:
      - "free-c0a4b3e4-8f5d-4c3e-9a2b-1d7e8f9c0a1b-123"
```

## Common Tasks

### Adding a New API Endpoint

**Ruby:**
1. Add endpoint constant to `RestfulClient::V1::END_POINTS`
2. Create parser in `api/parser/`
3. Create API class in `api/`
4. Add tests in `spec/`

**Go:**
1. Add method to `APIClient` in `pkg/api/api_client.go`
2. Define response struct
3. Create dedicated file (e.g., `new_endpoint.go`)
4. Add tests in `*_test.go`

### Adding New Configuration

**Ruby:**
1. Add attr_writer/accessor to `ChefLicensing::Config`
2. Update `ArgFetcher` and `EnvFetcher` if needed
3. Document in README
4. Add specs

**Go:**
1. Add field to `config.LicenseConfig` struct
2. Update `SetConfig` method
3. Document usage
4. Add tests

### Modifying TUI Flows

**Ruby:**
1. Edit YAML files in `lib/chef-licensing/tui_engine/`
2. Update `TuiEngine` actions
3. Test interactively

**Go:**
1. Edit `components/go/pkg/key_fetcher/interactions.yml`
2. Update action handlers in `action.go`
3. Update conditions in `conditions.go`
4. Test with TTY

## Optional Licensing Mode

Both implementations support optional licensing via configuration:

**Ruby:**
```ruby
ChefLicensing::Config.make_licensing_optional = true

# Or enforce for specific operations
ChefLicensing::Config.require_license_for do
  # This block requires a valid license
end
```

**Go:**
```go
// Check in code for optional licensing
if !requireLicense {
    return true, nil
}
```

## Important Notes

1. **Thread Safety**: Ruby uses `Mutex` for license operations; Go uses `sync.Once` for client initialization
2. **No In-Memory Caching**: License keys are fetched fresh on each call in Ruby
3. **TTY Detection**: Both implementations check for TTY to determine if interactive prompts are possible
4. **Spinner Suppression**: Spinners are suppressed in non-TTY environments
5. **Timeout Prompts**: Go YAML interactions support 60-second timeouts
6. **License Addition Restrictions**: Cannot add licenses in on-premises/local mode

## Testing Considerations

- Mock HTTP requests (WebMock in Ruby, custom mocks in Go)
- Test both TTY and non-TTY scenarios
- Test license state transitions (active → expired → grace)
- Test all license types (free, trial, commercial)
- Mock file operations for license storage
- Test configuration from multiple sources (env, args, direct)
- Test error handling and exception propagation

## Debugging Tips

**Ruby:**
```ruby
# Enable debug logging
ChefLicensing::Config.logger.level = Logger::DEBUG

# Check license service type
ChefLicensing::Context.local_licensing_service?

# Inspect license keys
ChefLicensing.license_keys
```

**Go:**
```go
// Add debug prints
fmt.Printf("Debug: %+v\n", someStruct)

// Check config
fmt.Printf("Config: %+v\n", config.GetConfig())
```

## Key Differences Between Ruby and Go Implementations

1. **Error Handling**: Ruby uses exceptions; Go uses error returns
2. **Async**: Ruby is synchronous; Go can leverage goroutines
3. **Testing**: Ruby uses RSpec DSL; Go uses table-driven tests
4. **Dependencies**: Ruby has heavier dependencies (TTY gems); Go is more lightweight
5. **File Handling**: Ruby uses PStore adapter; Go uses direct file I/O
6. **HTTP Client**: Ruby uses Faraday with caching; Go uses standard `net/http`

## Related Documentation

- [Chef Licensing Ruby README](components/ruby/README.md)
- [Chef Licensing Gem Specification](components/ruby/chef-licensing.gemspec)
- [Go Module Definition](components/go/go.mod)
- [GitHub Actions Workflow](.github/workflows/lint.yml)

## Contribution Guidelines

1. Follow language-specific style guides
2. Write tests for all new features
3. Update documentation
4. Ensure all linters pass
5. Add CHANGELOG entries
6. Test both Ruby and Go implementations if changing shared logic
7. Consider backward compatibility
8. Test with actual licensing server when possible

