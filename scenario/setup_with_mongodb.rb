require 'json'

require_relative './mongodb_client'

database_name = ARGV.first
raise "database name required" if database_name.nil? || database_name.empty?

client = MongodbScenario.client(database_name)
client.database.drop

Dir.glob("seed/mongodb/*.jsonl").each do |path|
  collection_name = File.basename(path, ".jsonl")
  docs = File.readlines(path, chomp: true).reject(&:empty?).map { |line| JSON.parse(line) }
  client[collection_name].insert_many(docs) unless docs.empty?
end

client.close
