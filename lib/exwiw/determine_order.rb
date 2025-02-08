require "json"

require_relative "./models"
require_relative "./util"

extract_target_table = "companies"
extract_target_ids = [1]

json = JSON.parse(File.read("schema.json"))

config = Config.deserialize(json)

ordered_table_names = ComputeTableDependencies.run(config.tables)

tables_by_name = config.tables.each_with_object({}) do |table, acc|
  acc[table.name] = table
end

def build_select(table_name, column_names)
  column_names.map { |cn| "#{table_name}.#{cn}" }.join(", ")
end

ordered_table_names.each do |table_name|
  table = tables_by_name[table_name]

  # pp table_name
  sql_asts = table.build_extract_query(extract_target_table, extract_target_ids, tables_by_name)

  if sql_asts.size == 1
    sql_ast = sql_asts[0]
    table_name = sql_ast[:from]
    column_names = sql_ast[:select]
    base_sql = "SELECT #{build_select(table_name, column_names)} FROM #{table_name}"

    if sql_ast[:where].size.positive?
      where_clauses = sql_ast[:where].map do |where|
        where.map { |k, v| "#{table_name}.#{k} IN (#{v.join(', ')})" }.join(" AND ")
      end
      puts base_sql + " WHERE " + where_clauses.join(" AND ") + ";"
    else
      puts base_sql + ";"
    end
  else
    base, *rest = sql_asts
    base_table_name = base[:base_table_name]
    base_column_names = table.column_names
    base_sql = "  SELECT #{build_select(base_table_name, base_column_names)} FROM #{table_name}"
    join_clauses = rest.map do |sql_ast|
      base_table_name = sql_ast[:base_table_name]
      foreign_key = sql_ast[:foreign_key]
      join_table_name = sql_ast[:join_table_name]
      join_key = sql_ast[:join_key]
      base_join = "JOIN #{join_table_name} ON #{base_table_name}.#{foreign_key} = #{join_table_name}.#{join_key}"

      if sql_ast[:where].size.positive?
        where_clauses = sql_ast[:where].map do |where|
          where.map { |k, v| "#{table_name}.#{k} IN (#{v.join(', ')})" }.join(" AND ")
        end
        base_join + " AND " + where_clauses.join(" AND ")
      else
        base_join
      end
    end

    puts base_sql + " " + join_clauses.join(" ") + ";"
  end
end
