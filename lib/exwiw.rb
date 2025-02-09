# frozen_string_literal: true

require_relative "exwiw/version"

require "serdes"

require_relative "exwiw/dumper"
require_relative "exwiw/runner"
require_relative "exwiw/belongs_to_relation"
require_relative "exwiw/table_column"
require_relative "exwiw/table"
require_relative "exwiw/config"

module Exwiw
  class Error < StandardError; end
  # Your code goes here...
end
