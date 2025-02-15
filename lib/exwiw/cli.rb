# frozen_string_literal: true

require 'logger'
require 'optparse'
require 'pathname'

require 'json'

require 'exwiw'

module Exwiw
  class CLI
    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
      @help = argv.empty?

      @database_host = nil
      @database_port = nil
      @database_user = nil
      @database_password = ENV["DATABASE_PASSWORD"]
      @output_dir = "dump"
      @config_dir = nil
      @database_adapter = nil
      @database_name = nil
      @target_table_name = nil
      @ids = []
      @log_level = :info

      parser.parse!(@argv)
    end

    def run
      if @help
        puts parser.help
      else
        validate_options!

        connection_config = ConnectionConfig.new(
          adapter: @database_adapter,
          host: @database_host,
          port: @database_port,
          user: @database_user,
          password: @database_password,
          database_name: @database_name,
        )

        dump_target = DumpTarget.new(
          table_name: @target_table_name,
          ids: @ids,
        )

        logger = build_logger

        Runner.new(
          connection_config: connection_config,
          output_dir: @output_dir,
          config_dir: @config_dir,
          dump_target: dump_target,
          logger: logger,
        ).run
      end
    end

    private def validate_options!
      if @database_adapter != "sqlite3"
        {
          "Target database host" => @database_host,
          "Target database port" => @database_port,
          "Database user" => @database_user,
          "Target database name" => @database_name,
          "Config dir" => @config_dir,
        }.each do |k, v|
          if v.nil?
            $stderr.puts "#{k} is required"
            exit 1
          end
        end

        if @database_password.nil? || @database_password.empty?
          $stderr.puts "environment variable 'DATABASE_PASSWORD' is required"
          exit 1
        end
      end

      valid_adapters = ["mysql2", "postgresql", "sqlite3"]
      unless valid_adapters.include?(@database_adapter)
        $stderr.puts "Invalid adapter. Available options are: #{valid_adapters.join(', ')}"
        exit 1
      end

      if @target_table_name.nil? || @target_table_name.empty?
        $stderr.puts "Target table is required"
        exit 1
      end

      if @ids.empty?
        $stderr.puts "At least one ID is required"
        exit 1
      end
    end

    private def build_logger
      formatter = proc do |severity, timestamp, progname, msg|
        formatted_ts = timestamp.strftime("%Y-%m-%d %H:%M:%S")
        "#{formatted_ts} [#{progname}]: #{msg}\n"
      end

      Logger.new(
        STDOUT,
        level: @log_level,
        datetime_format: "%Y-%m-%d %H:%M:%S",
        progname: "exwiw",
        formatter: formatter,
      )
    end

    private def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "exwiw #{Exwiw::VERSION}"
        opts.version = Exwiw::VERSION

        opts.on("-h", "--host=HOST", "Target database host") { |v| @database_host = v }
        opts.on("-p", "--port=PORT", "Target database port") { |v| @database_port = v }
        opts.on("-u", "--user=USERNAME", "Target database user") { |v| @database_user = v }
        opts.on("-o", "--output-dir=[DUMP_DIR_PATH]", "Output file path. default is dump/") do |v|
          @output_dir = v.end_with?("/") ? v[0..-2] : v
        end
        opts.on("-c", "--config-dir=CONFIG_DIR_PATH", "Config dir path.") do |v|
          @config_dir = v.end_with?("/") ? v[0..-2] : v
        end
        opts.on("-a", "--adapter=ADAPTER", "Database adapter") { |v| @database_adapter = v }
        opts.on("--database=DATABASE", "Target database name") { |v| @database_name = v }
        opts.on("--target-table=TABLE", "Target table for extraction") { |v| @target_table_name = v }
        opts.on("--ids=IDS", "Comma-separated list of identifiers") { |v| @ids = v.split(',') }
        opts.on("--log-level=LEVEL", "Log level (debug, info). default is info") { |v| @log_level = v.to_sym }

        opts.on("--help", "Print this help") do
          @help = true
        end
      end
    end
  end
end
