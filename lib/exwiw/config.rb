# frozen_string_literal: true

module Exwiw
  class Config
    include Serdes

    attribute :tables, array(Table)

    def self.from_symbol_keys(hash)
      from(hash.transform_keys(&:to_s))
    end
  end
end
