# frozen_string_literal: true

module Exwiw
  class Runner
    def initialize(connection_config, output_path, config_path, dump_target)
      @connection_config = connection_config
      @output_path = output_path
      @config_path = config_path
      @dump_target = dump_target
    end

    def run
      config = load_config
      adapter = build_adapter

      ordered_tables = DetermineTableProcessingOrder.run(config.tables)

      File.open(@output_path, 'w') do |file|
        ordered_tables.each do |table|
          query = build_query(table)
          results = adapter.execute(query)
          insert_sql = adapter.to_bulk_insert(results, table)
          file.puts(insert_sql)
        end
      end
    end

    private def load_config
      json = JSON.parse(File.read(@config_path))
      Config.from(json)
    end

    private def build_adapter
      case @connection_config["adapter"]
      when "sqlite3"
        SqliteAdapter.new(@connection_config)
      else
        raise "Unsupported adapter"
      end
    end

    private def build_query(table)
      # 테이블에 대한 쿼리를 생성하는 로직을 구현합니다.
      "SELECT * FROM \\#{table.name} WHERE ..." # 조건을 추가해야 합니다.
    end
  end
end
