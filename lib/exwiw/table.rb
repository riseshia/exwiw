# frozen_string_literal: true

module Exwiw
  class Table
    include Serdes

    attribute :name, String
    attribute :primary_key, String
    attribute :belongs_to_relations, array(BelongsToRelation)
    attribute :columns, array(TableColumn)

    def self.from_symbol_keys(hash)
      from(hash.transform_keys(&:to_s))
    end

    def column_names
      columns.map(&:name)
    end

    def belongs_to(table_name)
      belongs_to_relations.find { |relation| relation.table_name == table_name }
    end

    def build_extract_query(extract_target_table, extract_target_ids, tables_by_name)
      # target is itself
      if name == extract_target_table
        return [{
          from: name,
          where: [{ primary_key => extract_target_ids }],
          join: [],
          select: column_names,
        }]
      end

      # it is not related to target table
      if belongs_to_relations.empty?
        return [{
          from: name,
          where: [],
          join: [],
          select: column_names,
        }]
      end

      belongs_to_extract_target_table = belongs_to_relations.find { |relation| relation.table_name == extract_target_table }
      if belongs_to_extract_target_table
        key = belongs_to_extract_target_table.foreign_key
        return [{ from: name, where: [{ key => extract_target_ids }], join: [], select: column_names }]
      end

      ret = compute_dependency_to_table(extract_target_table, tables_by_name)

      if ret.empty?
        [{
          from: name,
          where: [],
          join: [],
          select: column_names,
        }]
      else
        last = ret.last
        last[:where] = [{ last[:foreign_key] => extract_target_ids }]
        ret
      end
    end

    private def compute_dependency_to_table(target_table_name, tables_by_name)
      return [] if belongs_to_relations.empty?

      results = belongs_to_relations.map do |relation|
        relation_table = tables_by_name[relation.table_name]

        if relation_table.name == target_table_name
          [{ base_table_name: name, foreign_key: relation.foreign_key,
             join_table_name: target_table_name, join_key: relation_table.primary_key }]
        else
          ret = relation_table.compute_dependency_to_table(target_table_name, tables_by_name)
          [{ base_table_name: name, foreign_key: relation.foreign_key,
             join_table_name: relation_table.name, join_key: relation_table.primary_key }] + ret
        end
      end.compact

      matched_dependencies = results.select do |dependency|
        dependency.last[:join_table_name] == target_table_name
      end

      return [] if matched_dependencies.empty?

      matched_dependencies.min_by(&:size)
    end
  end
end
