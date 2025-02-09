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
    let(:config_path) { 'test_config.json' }
    let(:dump_target) { double('DumpTarget') }
    let(:runner) { Runner.new(connection_config, output_dir, config_path, dump_target) }

    before do
      allow(File).to receive(:read).with(config_path).and_return('{ "adapter": "sqlite3", "tables": [] }')
    end

    it 'writes bulk insert SQL to the output file' do
      expect { runner.run }.not_to raise_error
    end
  end
end
