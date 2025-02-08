# frozen_string_literal: true

require "active_record"
require "database_cleaner/active_record"

require "exwiw"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
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

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :companies, force: :cascade do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :users, force: :cascade do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.references :company, null: false, foreign_key: true
    t.timestamps
  end

  create_table :products, force: :cascade do |t|
    t.string :name, null: false
    t.decimal :price, precision: 10, scale: 2, null: false
    t.references :company, null: false, foreign_key: true
    t.timestamps
  end

  create_table :orders, force: :cascade do |t|
    t.references :company, null: false, foreign_key: true
    t.timestamps
  end

  create_table :order_items, force: :cascade do |t|
    t.references :order, null: false, foreign_key: true
    t.references :product, null: false, foreign_key: true
    t.timestamps
  end

  create_table :transactions, force: :cascade do |t|
    t.references :order, null: false, foreign_key: true
    t.string :type, null: false
    t.decimal :amount, precision: 10, scale: 2, null: false
    t.timestamps
  end

  create_table :reviews, force: :cascade do |t|
    t.references :reviewable, polymorphic: true, null: false
    t.references :user, null: false, foreign_key: true
    t.integer :rating, null: false
    t.text :content, null: false
    t.timestamps
  end
end