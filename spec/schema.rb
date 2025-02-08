# frozen_string_literal: true

require "active_record"

ActiveRecord::Schema.define do
  self.verbose = false

  create_table :shops, force: :cascade do |t|
    t.string :name, null: false
    t.timestamps
  end

  create_table :users, force: :cascade do |t|
    t.string :name, null: false
    t.string :email, null: false
    t.references :shop, null: false, foreign_key: true
    t.timestamps
  end

  create_table :products, force: :cascade do |t|
    t.string :name, null: false
    t.decimal :price, precision: 10, scale: 2, null: false
    t.references :shop, null: false, foreign_key: true
    t.timestamps
  end

  create_table :orders, force: :cascade do |t|
    t.references :shop, null: false, foreign_key: true
    t.references :user, null: false, foreign_key: true
    t.timestamps
  end

  create_table :order_items, force: :cascade do |t|
    t.references :order, null: false, foreign_key: true
    t.references :product, null: false, foreign_key: true
    t.integer :quantity, null: false, default: 1
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
