# frozen_string_literal: true

module Exwiw
  class Runner
    def initialize(connection_config, output, config_path)
      @connection_config = connection_config
      @output = output
      @config_path = config_path
    end

    def run
      tables = load_tables
      puts tables
    end

    private def load_tables
      json = JSON.parse(File.read(@config_path))
      Config.from(json)
    end
  end
end
