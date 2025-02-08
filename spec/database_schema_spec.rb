# frozen_string_literal: true

RSpec.describe 'Database schema' do
  it 'creates the companies table' do
    expect(ActiveRecord::Base.connection.table_exists?(:companies)).to be true
  end

  it 'creates the users table' do
    expect(ActiveRecord::Base.connection.table_exists?(:users)).to be true
  end

  it 'creates the products table' do
    expect(ActiveRecord::Base.connection.table_exists?(:products)).to be true
  end

  it 'creates the orders table' do
    expect(ActiveRecord::Base.connection.table_exists?(:orders)).to be true
  end

  it 'creates the order_items table' do
    expect(ActiveRecord::Base.connection.table_exists?(:order_items)).to be true
  end

  it 'creates the transactions table' do
    expect(ActiveRecord::Base.connection.table_exists?(:transactions)).to be true
  end

  it 'creates the reviews table' do
    expect(ActiveRecord::Base.connection.table_exists?(:reviews)).to be true
  end
end