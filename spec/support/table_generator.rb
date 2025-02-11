# frozen_string_literal: true

module TableGenerator
  def shops_table
    @shops_table ||= Exwiw::Table.from_symbol_keys({
      name: 'shops',
      primary_key: 'id',
      belongs_tos: [],
      columns: [
        Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'name' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
        Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
      ]
    })
  end

  def users_table(masking_strategy: :replace_with)
    @users_table_by_ms ||= {}
    @users_table_by_ms[masking_strategy] ||=
      begin
        email_data =
          case masking_strategy
          when :replace_with
            { name: 'email', replace_with: 'masked{id}@example.com' }
          when :raw_sql
            { name: 'email', raw_sql: "('rawsql' || users.id || '@example.com')" }
          else
            raise ArgumentError, "Unknown masking strategy: #{masking_strategy}"
          end

        Exwiw::Table.from_symbol_keys({
          name: 'users',
          primary_key: 'id',
          belongs_tos: [
            Exwiw::BelongsTo.from_symbol_keys({
              foreign_key: 'shop_id',
              table_name: 'shops'
            }),
          ],
          columns: [
            Exwiw::TableColumn.from_symbol_keys({ name: 'id' }),
            Exwiw::TableColumn.from_symbol_keys({ name: 'name' }),
            Exwiw::TableColumn.from_symbol_keys(email_data),
            Exwiw::TableColumn.from_symbol_keys({ name: 'shop_id' }),
            Exwiw::TableColumn.from_symbol_keys({ name: 'created_at' }),
            Exwiw::TableColumn.from_symbol_keys({ name: 'updated_at' }),
          ]
        })
      end
  end

  def products_table
    @products_table ||= Exwiw::Table.from_symbol_keys({
      name: 'products',
      primary_key: 'id',
      belongs_tos: [
        Exwiw::BelongsTo.from_symbol_keys({
          foreign_key: 'shop_id',
          table_name: 'shops'
        }),
      ],
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
    @orders_table ||= Exwiw::Table.from_symbol_keys({
      name: 'orders',
      primary_key: 'id',
      belongs_tos: [
        Exwiw::BelongsTo.from_symbol_keys({
          foreign_key: 'shop_id',
          table_name: 'shops'
        }),
        Exwiw::BelongsTo.from_symbol_keys({
          foreign_key: 'user_id',
          table_name: 'users'
        }),
      ],
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
    @order_items_table ||= Exwiw::Table.from_symbol_keys({
      name: 'order_items',
      primary_key: 'id',
      belongs_tos: [
        Exwiw::BelongsTo.from_symbol_keys({
          foreign_key: 'order_id',
          table_name: 'orders'
        }),
        Exwiw::BelongsTo.from_symbol_keys({
          foreign_key: 'product_id',
          table_name: 'products'
        }),
      ],
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
    @transactions_table ||= Exwiw::Table.from_symbol_keys({
      name: 'transactions',
      primary_key: 'id',
      belongs_tos: [
        Exwiw::BelongsTo.from_symbol_keys({
          foreign_key: 'order_id',
          table_name: 'orders'
        }),
      ],
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
    @reviews_table ||= Exwiw::Table.from_symbol_keys({
      name: 'reviews',
      primary_key: 'id',
      belongs_tos: [
        Exwiw::BelongsTo.from_symbol_keys({
          foreign_key: 'user_id',
          table_name: 'users'
        }),
      ],
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
    @system_announcements_table ||= Exwiw::Table.from_symbol_keys({
      name: 'system_announcements',
      primary_key: 'id',
      belongs_tos: [],
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
