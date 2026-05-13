# frozen_string_literal: true

module Exwiw
  class MongodbField
    include Serdes

    attribute :name, String
    attribute :replace_with, optional(String), skip_serializing_if_nil: true

    def self.from_symbol_keys(hash)
      from(hash.transform_keys(&:to_s))
    end

    def to_hash
      super.compact
    end
  end
end
