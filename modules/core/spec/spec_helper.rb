ENV["RAILS_ENV"] ||= "test"

require "simplecov"

SimpleCov.profiles.define "clean_architecture" do
  add_filter %r{^/config/}
  add_filter %r{^/test/}
  add_filter %r{^/spec/}
  add_filter %r{^/db/}
  add_filter "version.rb"

  load_profile "test_frameworks"

  track_files "{app,lib}/**/*.rb"
end

SimpleCov.minimum_coverage 100
SimpleCov.start "clean_architecture"

require "core"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not really exist
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.profile_examples = 10 # Print the 10 slowest examples
  config.order = :random
  Kernel.srand config.seed # allows you to use `--seed`
  config.disable_monkey_patching! # Limits the available syntax to the non-monkey patched syntax
end
