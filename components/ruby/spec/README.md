# Test harness notes for the chef-licensing specs

## Purpose

This file documents the decisions made in `spec/spec_helper.rb` to keep the
suite deterministic and hermetic.

## Key points

- WebMock is required before the library (`require "webmock/rspec"`) so any
  HTTP client initialization that happens at require-time is intercepted.
  This prevents accidental real HTTP connections during test bootstrap.

- The tests set a deterministic license server URL via
  `ENV["CHEF_LICENSE_SERVER"]` and `ENV["LICENSE_SERVER"]` so tests don't
  rely on developer/CI environment values or persisted files that might
  point to production servers.

- `ENV.delete("CHEF_LICENSE_KEY")` is used to ensure tests don't pick up
  real credentials from the environment.

- A suite-level temporary HOME (`TMP_TEST_HOME`) is created early so
  require-time code that consults `ENV["HOME"]` or `ENV["USERPROFILE"]`
  doesn't see a developer/CI home. Some specs still require a fresh HOME
  per-example; the harness provides an `around(:each)` hook that swaps in a
  temporary HOME for the duration of those examples.

- Tests that need HTTP interactions should stub them explicitly using
  WebMock's `stub_request`. Consider adding common stubs to
  `spec/support/license_server_stubs.rb` to reduce duplication.

## Running the tests


From the `components/ruby` directory run:

```bash
bundle exec rspec --format=documentation
```

If you only want to run a single spec file:

```bash
bundle exec rspec spec/path/to/file_spec.rb
```

## Adding a new spec

- If your spec touches the user's HOME, prefer creating temporary dirs
  under `Dir.mktmpdir` and avoid writing into the suite-level HOME
  directly. Use the provided per-example HOME swap when you need a
  pristine HOME for each example.

- If your spec makes HTTP calls, add a `stub_request` for the exact
  request the code will issue. If multiple specs need the same stubs,
  factor them into `spec/support/license_server_stubs.rb` and require that
  from `spec/spec_helper.rb`.

## Contact

If you have questions about why this setup exists, check the Git history
for `spec/spec_helper.rb` or ask the maintainer team.
