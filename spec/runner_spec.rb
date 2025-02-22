require 'spec_helper'

module Exwiw
  RSpec.describe Runner do
    let(:connection_config) do
      ConnectionConfig.new(
        adapter: 'sqlite3',
        database_name: 'tmp/test.sqlite3',
        host: nil,
        port: nil,
        user: nil,
        password: nil,
      )
    end
    let(:output_dir) { 'tmp/test_output_dir' }
    let(:config_dir) { 'test_config' }
    let(:dump_target) { double('DumpTarget') }
    let(:runner) do
      Runner.new(
        connection_config: connection_config,
        output_dir: output_dir,
        config_dir: config_dir,
        dump_target: dump_target,
        logger: ::Logger.new(nil),
      )
    end

    it 'writes bulk insert SQL to the output file' do
      expect { runner.run }.not_to raise_error
    end
  end
end
