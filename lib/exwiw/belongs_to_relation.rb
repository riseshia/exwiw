# frozen_string_literal: true

module Exwiw
  class BelongsToRelation
    include Serdes

    attribute :polymorphic, Boolean
    attribute :polymorphic_name, optional(String)
    attribute :foreign_type, optional(String)
    attribute :foreign_key, String
    attribute :table_name, optional(String)

    def self.from_symbol_keys(hash)
      from(hash.transform_keys(&:to_s))
    end
  end
end
