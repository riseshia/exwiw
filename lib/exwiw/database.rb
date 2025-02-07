# frozen_string_literal: true

module Exwiw
  class Database
    include Serdes

    attribute :adapter, String
    attribute :name, String
  end
end
