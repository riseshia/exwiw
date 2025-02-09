# frozen_string_literal: true

require "active_record"
require "database_cleaner/active_record"

require "exwiw"

# Load the schema before each test suite run
require_relative 'support/table_generator'

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
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)

    require_relative 'support/schema'
    require_relative 'support/models'
    require_relative 'support/record_creation'
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)
