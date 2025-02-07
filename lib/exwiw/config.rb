# frozen_string_literal: true

module Exwiw
  class Config
    include Serdes

    attribute :database, Database
    attribute :tables, array(Table)
  end
end
