# frozen_string_literal: true

module TableGenerator
  def shops_table
    Exwiw::Table.from_symbol_keys({
      name: 'shops',
      primary_key: 'id',
      belongs_to_relations: [],
      polymorphic_as: [],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'name' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def users_table
    Exwiw::Table.from_symbol_keys({
      name: 'users',
      primary_key: 'id',
      belongs_to_relations: [
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'shop_id',
          table_name: 'shops'
        }),
      ],
      polymorphic_as: [],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'name' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'email' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'shop_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def products_table
    Exwiw::Table.from_symbol_keys({
      name: 'products',
      primary_key: 'id',
      belongs_to_relations: [
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'shop_id',
          table_name: 'shops'
        }),
      ],
      polymorphic_as: ['reviewable'],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'name' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'price' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'shop_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def orders_table
    Exwiw::Table.from_symbol_keys({
      name: 'orders',
      primary_key: 'id',
      belongs_to_relations: [
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'shop_id',
          table_name: 'shops'
        }),
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'user_id',
          table_name: 'users'
        }),
      ],
      polymorphic_as: [],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'shop_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'user_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def order_items_table
    Exwiw::Table.from_symbol_keys({
      name: 'order_items',
      primary_key: 'id',
      belongs_to_relations: [
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'order_id',
          table_name: 'orders'
        }),
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'product_id',
          table_name: 'products'
        }),
      ],
      polymorphic_as: [],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'quantity' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'order_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'product_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def transactions_table
    Exwiw::Table.from_symbol_keys({
      name: 'transactions',
      primary_key: 'id',
      belongs_to_relations: [
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'order_id',
          table_name: 'orders'
        }),
      ],
      polymorphic_as: [],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'type' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'amount' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'order_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def reviews_table
    Exwiw::Table.from_symbol_keys({
      name: 'reviews',
      primary_key: 'id',
      belongs_to_relations: [
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: true,
          polymorphic_name: 'reviewable',
          foreign_key: 'reviewable_id',
          foreign_type: 'reviewable_type',
        }),
        Exwiw::BelongsToRelation.from_symbol_keys({
          polymorphic: false,
          foreign_key: 'user_id',
          table_name: 'users'
        }),
      ],
      polymorphic_as: ['reviewable'],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'rating' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'content' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'reviewable_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'reviewable_type' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'user_id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def system_announcements_table
    Exwiw::Table.from_symbol_keys({
      name: 'system_announcements',
      primary_key: 'id',
      belongs_to_relations: [],
      polymorphic_as: [],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'title' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'content' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end
end
