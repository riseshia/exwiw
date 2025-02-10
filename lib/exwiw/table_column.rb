# frozen_string_literal: true

module Exwiw
  class TableColumn
    include Serdes

    attribute :name, String
    attribute :replace_with, optional(String)

    def self.from_symbol_keys(hash)
      from(hash.transform_keys(&:to_s))
    end
  end
end
