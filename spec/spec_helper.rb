# frozen_string_literal: true

require "exwiw"

require_relative 'support/table_generator'
require_relative 'support/bootstrap_databases'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include(TableGenerator)

  config.before(:suite) do
    BootstrapDatabases.run
  end
end
