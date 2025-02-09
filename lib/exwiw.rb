# frozen_string_literal: true

require_relative "exwiw/version"

require "serdes"

require_relative "exwiw/adapter"
require_relative "exwiw/adapter/sqlite_adapter"
require_relative "exwiw/determine_table_processing_order"
require_relative "exwiw/query_ast"
require_relative "exwiw/query_ast_builder"
require_relative "exwiw/runner"
require_relative "exwiw/belongs_to_relation"
require_relative "exwiw/table_column"
require_relative "exwiw/table"
require_relative "exwiw/config"

module Exwiw
  DumpTarget = Struct.new(:table_name, :ids, keyword_init: true)
  ConnectionConfig = Struct.new(:adapter, :host, :port, :user, :password, :database_name, keyword_init: true)
end
