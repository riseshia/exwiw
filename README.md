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

## Usage

### Command

```bash
# dump & masking all records from database to dump.sql based on schema.json
# pass database password as an environment variable 'DATABASE_PASSWORD'
exwiw \
  --adaptor=mysql2 \
  --host=localhost \
  --port=3306 \
  --user=reader \
  --database=app_production \
  --config=schema.json \
  --output=dump.sql
```

### Generator

the config generator is provided as Rake task.

```bash
# generate schema.json
bundle exec rake exwiw:schema:generate
```

### Configuration

```json
{
    "database": {
        "name": "app_production",
    },
    "tables": [{
        "name": "users",
        "primary_key": "id",
        "belongs_to": [{
            "name": "companies",
            "foreign_key": "company_id"
        }],
        "polymorphic_as": [
            "loggable"
        ],
        "columns": [{
            "name": "id",
        }, {
            "name": "email",
            "mask": {
                "type": "replaced_with",
                "value": "user{id}@example.com"
            }
        }, {
            "name": "company_id"
        }]
    }]
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/riseshia/exwiw.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
