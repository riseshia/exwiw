# frozen_string_literal: true

module Exwiw
  class MongodbCollectionConfig
    include Serdes

    # MongoDB-native names. Intentionally re-declared instead of inheriting
    # from TableConfig — Serdes does not propagate attribute declarations
    # across class boundaries.
    attribute :name, String
    attribute :primary_key, String
    attribute :filter, optional(String), skip_serializing_if_nil: true
    attribute :belongs_tos, array(BelongsTo)
    attribute :fields, array(MongodbField)
    attribute :bulk_insert_chunk_size, optional(Integer), skip_serializing_if_nil: true

    def self.from_symbol_keys(hash)
      from(JSON.parse(hash.to_json))
    end
  end
end
