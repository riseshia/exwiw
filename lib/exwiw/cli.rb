# frozen_string_literal: true

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
      @output = "dump.sql"
      @config_path = "schema.json"

      parser.parse!(@argv)
    end

    def run
      if @help
        puts parser.help
      else
        validate_options!

        connection_config = ConnectionConfig.new(
          host: @database_host,
          port: @database_port,
          user: @database_user,
          password: @database_password,
        )

        Runner.new(connection_config, @output, @config_path).run
      end
    end

    ConnectionConfig = Struct.new(:host, :port, :user, :password, keyword_init: true)

    private def validate_options!
      {
        "Target database host" => @database_host,
        "Target database port" => @database_port,
        "Database user" => @database_user,
        "Output file path" => @output,
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

    private def parser
      @parser ||= OptionParser.new do |opts|
        opts.banner = "exwiw #{Exwiw::VERSION}"
        opts.version = Exwiw::VERSION

        opts.on("-h", "--host=HOST", "Target database host") { |v| @database_host = v }
        opts.on("-p", "--port=PORT", "Target database port") { |v| @database_port = v }
        opts.on("-u", "--user=USERNAME", "Target database user") { |v| @database_user = v }
        opts.on("-o", "--output=DUMP_FILE_PATH", "Output file path. default is dump.sql") { |v| @output = v }
        opts.on("-c", "--config=[CONFIG_FILE_PATH]", "Config file path. default is schema.json") { |v| @config_path = v }

        opts.on("--help", "Print this help") do
          @help = true
        end
      end
    end
  end
end
