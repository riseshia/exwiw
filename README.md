# Exwiw

Export What I Want (Exwiw) is a Ruby gem that allows you to export records from a database to a dump file(to specifically, the full list of INSERT sql) on the specified conditions.

## When to use

Most of case in developing a software, There is no better choice than the same data in production.
You might make well-crafted data, but it's very very hard to maintain.

If you find the way to maintain the data for develoment env, then exwiw might be a solution for that.

- Export the full database and mask data and import to another database.
- Setup some system to replicate and mask data in real-time to another database.


You want to export only the data you want to export.

## Features

- Export the full list of INSERT sql for the specified conditions.
- Provide serveral masking options for sensitive columns.
- Provide config generator for ActiveRecord.

## Installation

```bash
bundle add exwiw
```

Most of cases, you want to add 'require: false' to the Gemfile.

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install exwiw
```

## Supported Databases

- sqlite3

## Usage

### Command

```bash
# dump & masking all records from database to dump.sql based on schema.json
# pass database password as an environment variable 'DATABASE_PASSWORD'
exwiw \
  --adapter=mysql2 \
  --host=localhost \
  --port=3306 \
  --user=reader \
  --database=app_production \
  --config=schema.json \
  --target-table=shops \
  --ids=1 \ # comma separated ids
  --output-dir=dump
```

This command will generate sql files in the `dump` directory.

- `dump/insert-{idx}-{table_name}.sql`
- `dump/delete-{idx}-{table_name}.sql`

idx means the order of the dump. bigger idx might depend on smaller idx,
so you should import the dump in order.

you need to delete the records before importing the dump,
`delete-{idx}-{table_name}.sql` will help you to do that.
This sql will delete "all" related records to the extract targets.
idx meaning is the same as insert sql.

### Generator

the config generator is provided as Rake task.

```bash
# generate schema.json
bundle exec rake exwiw:schema:generate
```

### Configuration

```json
{
    "tables": [{
        "name": "users",
        "primary_key": "id",
        "belongs_to": [{
            "name": "companies",
            "foreign_key": "company_id"
        }],
        "columns": [{
            "name": "id",
        }, {
            "name": "email",
            "replace_with": "user{id}@example.com"
        }, {
            "name": "company_id"
        }]
    }]
}
```

### Masking

`exwiw` provides several options for masking value.

#### `replace_with`

It will replace the value with the specified string,
and you can use the column name with `{}` to replace the value with the column value.

For example, Let assume we have the record which id is 1,
then "user{id}@example.com" will be replaced with "user1@example.com".

#### `raw_sql`

It will used instead of the original value.

For example, `"raw_sql": "CONCAT('user', shops.id, '@example.com')"` is equivalent to
`"replace_with": "user{id}@example.com"`.
This is useful when you want to transform with functions provided by the database.

Notice that you are recommended to clearify table name of column to avoid ambiguity.

If it used with `replace_with`, `replace_with` will be ignored.

#### `map`

XXX: TODO

Given value will be evaluated as Ruby code, and treated as the proc.

```
"map": "proc { |r| 'user' + v['id'].to_s + '@example.com' }"
```

which is equivalent to `"replace_with": "user{id}@example.com"`.

Notice this is the most powerful option, but you should be careful to use this option.
Because this transformation occured on exwiw process, so much slower than other options.
Most of case, this option is not recommended.

## How it works

- Load the table information from the specified config file.
- Calculate the dependency between tables.
- Generate the full list of INSERT sql based on the specified conditions.
  - If the processing table has no relation with target tables, then dump all records.
  - If the processing table has relation with target tables, then dump the records which are related to the target tables.
- Generate the full list of DELETE sql based on the specified conditions.
  - If the processing table has no relation with target tables, then delete all records.
  - If the processing table has relation with target tables, then delete the records which are related to the target tables.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/riseshia/exwiw.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
