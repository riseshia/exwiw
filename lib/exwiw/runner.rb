# frozen_string_literal: true

require "fileutils"

module Exwiw
  class Runner
    def initialize(
      connection_config:,
      output_dir:,
      config_dir:,
      dump_target:,
      logger:
    )
      @connection_config = connection_config
      @output_dir = output_dir
      @config_dir = config_dir
      @dump_target = dump_target
      @logger = logger
    end

    def run
      adapter = Adapter.build(@connection_config, @logger)
      tables = load_table_config

      @logger.info("Determining table processing order...")
      ordered_table_names = DetermineTableProcessingOrder.run(tables)

      if !Dir.exist?(@output_dir)
        FileUtils.mkdir_p(@output_dir)
      end

      table_by_name = tables.each_with_object({}) { |table, hash| hash[table.name] = table }

      total_size = ordered_table_names.size
      ordered_table_names.each_with_index do |table_name, idx|
        @logger.info("Processing table '#{table_name}'... (#{idx + 1}/#{total_size})")
        table = table_by_name.fetch(table_name)

        query_ast = adapter.build_query(table, @dump_target, table_by_name)
        results = adapter.execute(query_ast)
        record_num = results.size

        if record_num.zero?
          @logger.info("  No records matched. skip this table.")
          next
        end
        @logger.debug("  Generate INSERT statement...")

        chunk_size = table.bulk_insert_chunk_size
        chunks = chunk_size ? results.each_slice(chunk_size).to_a : [results]
        insert_sql = chunks.map { |chunk_rows| adapter.to_bulk_insert(chunk_rows, table) }.join("\n")

        @logger.info("  Generated INSERT statement for #{record_num} records (#{chunks.size} statement(s)).")
        insert_idx = (idx + 1).to_s.rjust(3, '0')
        File.open(File.join(@output_dir, "insert-#{insert_idx}-#{table_name}.#{adapter.output_extension}"), 'w') do |file|
          file.puts(insert_sql)
        end

        if adapter.supports_bulk_delete?
          @logger.debug("  Generate DELETE statement...")
          delete_sql = adapter.to_bulk_delete(query_ast, table)
          if @logger.debug?
            @logger.debug("  Generated DELETE statement:\n#{delete_sql}")
          else
            @logger.info("  Generated DELETE statement.")
          end
          delete_idx = (total_size - idx).to_s.rjust(3, '0')
          File.open(File.join(@output_dir, "delete-#{delete_idx}-#{table_name}.#{adapter.output_extension}"), 'w') do |file|
            file.puts(delete_sql)
          end
        end
      end
    end

    private def load_table_config
      Dir[File.join(@config_dir, "*.json")].map do |file|
        json = JSON.parse(File.read(file))
        TableConfig.from(json)
      end
    end

    private def build_adapter
      case @connection_config["adapter"]
      when "sqlite3"
        Sqlite3Adapter.new(@connection_config)
      else
        raise "Unsupported adapter"
      end
    end
  end
end
