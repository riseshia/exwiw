# frozen_string_literal: true

module Exwiw
  class EmbeddedIn
    include Serdes

    attribute :collection_name, String
    attribute :path, String

    def self.from_symbol_keys(hash)
      from(hash.transform_keys(&:to_s))
    end
  end
end
