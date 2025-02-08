# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

class Company < ApplicationRecord
  has_many :users
  has_many :products
  has_many :orders
end

class User < ApplicationRecord
  belongs_to :company
end

class Product < ApplicationRecord
  belongs_to :company
  has_many :order_items
  has_many :orders, through: :order_items
  has_many :reviews, as: :reviewable
end

class Order < ApplicationRecord
  belongs_to :company
  has_many :order_items
  has_many :products, through: :order_items
  has_one :payment_transaction
  has_one :refund_transaction
end

class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
end

class PaymentTransaction < Transaction
  belongs_to :order
end

class PaymentTransaction < Transaction
  belongs_to :order
end

class RefundTransaction < ApplicationRecord
  belongs_to :order
end

class Review < ApplicationRecord
  belongs_to :reviewable, polymorphic: true
  belongs_to :user
end

class SystemAnnouncement < ApplicationRecord
end