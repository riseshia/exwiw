# exwiw:schema:generate のテスト容易化と複数DBの fail-fast 対応

## Context (なぜやるか)

[lib/tasks/exwiw.rake](lib/tasks/exwiw.rake) は 62 行のロジックを Rake task ブロック内に直書きしているため、

1. **テストが書けない**: Rails アプリ起動 + ファイル I/O が混ざっており、現状 spec が一つも無い
2. **Rails の複数 DB (`connects_to`) 構成で silent failure する**: 別 DB にぶら下がるモデルも `ActiveRecord::Base.descendants` で取れるが、生成された JSON にどの DB に属するかの情報が無いため、後段の Runner / CLI が誤った DB に対して抽出を試みる

(1) を解決するために introspection ロジックを `Exwiw::SchemaGenerator` クラスに切り出し、(2) は完全対応するとスキーマ形式 / Runner / CLI まで波及する大改修になるため、**今回は検出して fail-fast** に留め、後続課題として記録する。

リファクタ過程で latent bug (STI サブクラスの `belongs_to` が抜け落ちる、後述) も併せて直す。

## 変更対象ファイル

新規:
- [lib/exwiw/schema_generator.rb](lib/exwiw/schema_generator.rb) — 抽出したクラス
- [spec/schema_generator_spec.rb](spec/schema_generator_spec.rb) — 単体テスト
- [spec/fixtures/schema/](spec/fixtures/schema/) — スナップショット fixture 一式 (`shops.json` 等)

変更:
- [lib/tasks/exwiw.rake](lib/tasks/exwiw.rake) — クラスへ委譲する数行に圧縮
- [lib/exwiw.rb](lib/exwiw.rb:18) — `require_relative "exwiw/schema_generator"` 追加 (line 18 付近)
- [CHANGELOG.md](CHANGELOG.md) — Unreleased に項目追加

## API 設計: `Exwiw::SchemaGenerator`

```ruby
module Exwiw
  class SchemaGenerator
    class MultipleDatabasesNotSupportedError < StandardError; end

    # Rake task 用ファクトリ。Rails 依存はここに閉じ込める
    def self.from_rails_application(output_dir:)
      Rails.application.eager_load!
      new(models: ActiveRecord::Base.descendants, output_dir: output_dir)
    end

    def initialize(models:, output_dir:)
      @models = models
      @output_dir = output_dir
    end

    def generate!
      tables = build_tables       # validation を内包
      write_files(tables)
      tables
    end

    # public: pure (filesystem に触らない)。テストで主に使う
    def build_tables
      validate_single_database!(concrete_models)
      ...
    end

    # public: I/O 単独
    def write_files(tables)
      ...
    end

    private

    def concrete_models
      @models.reject(&:abstract_class?).select(&:table_exists?)
    end

    def validate_single_database!(models)
      ...
    end
  end
end
```

ポイント:
- `build_tables` を public にして spec は in-memory な `TableConfig` 配列で構造アサートできる (tmp dir を介さない)
- I/O は `#generate!` 経由のスナップショット test 1 本だけで網羅
- Rails 呼び出し (`Rails.application.eager_load!` / `Rails.application`) は `from_rails_application` のみ

Rake task は以下まで薄くなる:

```ruby
task generate: :environment do
  require "exwiw"
  Exwiw::SchemaGenerator.from_rails_application(
    output_dir: ENV["OUTPUT_DIR_PATH"] || "exwiw"
  ).generate!
end
```

## STI サブクラスの belongs_to 集約 (latent bug 修正)

現状コードは `next if table_by_name[model.table_name]` で同一 `table_name` を持つ STI サブクラスを早い者勝ちで捨てている ([lib/tasks/exwiw.rake:18](lib/tasks/exwiw.rake:18))。`Transaction` (基底) → `PaymentTransaction` / `RefundTransaction` のような構成では、`Transaction` が先に処理されると `belongs_to :order` が失われる。

新クラスでは concrete_models を `group_by(&:table_name)` してから、各グループ内で **`belongs_to` reflection を全て集めて `(table_name, foreign_key)` の組で uniq** する。primary_key と column_names は同一 table を共有する以上どのサブクラスも同じはずなので 1 つ目の値を使えばよい。

回帰テスト: `Transaction` 系 3 クラスを順を変えて渡しても `transactions` テーブルの `belongs_tos` に `orders` が含まれることを確認。

## 複数 DB 検出 (fail-fast)

`#build_tables` 冒頭、concrete_models 抽出直後に:

```ruby
specs = concrete_models.map(&:connection_specification_name).uniq
if specs.size > 1
  raise MultipleDatabasesNotSupportedError, <<~MSG
    exwiw does not yet support Rails multiple-database setup.
    Detected connection specifications: #{specs.inspect}
    Track progress / share use case at: <issue url placeholder>
  MSG
end
```

エッジケース:
- 単一 abstract `ApplicationRecord` + `connects_to writing:/reading:` (role 切替) → 子孫の `connection_specification_name` は同一 (role ではなく spec 名) → 通過 ✓
- shard 構成 (`connects_to shards:`) も spec 名は同一 → 通過 (sharding は別問題、TODO に残すのみ)
- 真の複数 DB (DB 毎に abstract base を分ける典型構成) → spec 名が異なる → raise ✓

`connection_specification_name` は public ではないが Rails 6.1〜8.x で安定。コメントで Rails バージョン依存を明記する。

## テスト戦略

[spec/schema_generator_spec.rb](spec/schema_generator_spec.rb):

- `before(:all)` で `ActiveRecord::Base.establish_connection(database_config(:sqlite3))` し [script/models.rb](script/models.rb) を `require_relative`。sqlite3 DB は既に [spec/spec_helper.rb:26](spec/spec_helper.rb:26) の `BootstrapDatabases.run` で用意済み
- **構造アサート (主)**: `build_tables` を呼び、各 `TableConfig` の `name` / `primary_key` / `belongs_tos` (foreign_key set) / `column_names` (sorted set) を期待値と比較。column 順序の DB 依存を逃れられる
- **スナップショット (補)**: `Dir.mktmpdir` に `generate!` し、各 JSON を `JSON.parse` 比較で `spec/fixtures/schema/<table>.json` と突き合わせる
- **merge 動作**: 既存 `filter` / `bulk_insert_chunk_size` 入りの fixture を tmp dir に配置 → `generate!` → 上記が保持されることを確認 ([lib/exwiw/table_config.rb:69](lib/exwiw/table_config.rb:69) の merge を経路で踏む)
- **STI 集約**: 模型を `[PaymentTransaction, RefundTransaction, Transaction]` 順 / 逆順で渡し、`transactions` の belongs_tos に `orders` が含まれること
- **polymorphic skip**: `Review#belongs_tos` に `reviewable` が含まれず `users` が含まれること
- **複数 DB 検出**: 2 つのモデルの `connection_specification_name` を `allow(...).to receive(...)` で別値にスタブし `MultipleDatabasesNotSupportedError` を期待

sqlite3 だけで十分 (introspection は AR レイヤで行われ adapter 非依存)。マルチアダプタ網羅は不要。

fixture JSON は初回生成して目視レビュー → コミット。既存の [scenario/sqlite3-schema/](scenario/sqlite3-schema/) (手書き混じり、`reviews.json` 欠) はそのままにし、`spec/fixtures/schema/` を独立に管理する。

## 検証手順

1. `mise exec ruby@latest -- bundle exec rspec spec/schema_generator_spec.rb` — 新 spec が通る
2. `mise exec ruby@latest -- bundle exec rspec` — 既存テスト 0 リグレッション
3. 手動: 一時ディレクトリに schema 生成
   ```sh
   rm -rf tmp/sg && mise exec ruby@latest -- ruby -Ilib -e '
     require "active_record"; require_relative "script/database_config"
     ActiveRecord::Base.establish_connection(database_config(:sqlite3))
     require_relative "script/models"
     require "exwiw/schema_generator"
     Exwiw::SchemaGenerator.new(models: ActiveRecord::Base.descendants, output_dir: "tmp/sg").generate!
   '
   diff <(jq -S . tmp/sg/transactions.json) <(jq -S . scenario/sqlite3-schema/transactions.json)
   ```
4. 複数 DB ケースの手動確認: irb で `allow` スタブが面倒なら省略 (spec で十分)

## リスク / トレードオフ

- **`connection_specification_name` 依存**: 私的 API 寄り。Rails 8 までは安定だがコメントで明記。将来 break したら spec で気付ける
- **fixture の rot**: AR 内部や script/models.rb の変更で column が増減すると snapshot が壊れる。構造アサートを主にすることで影響を局所化
- **`Rails.application.eager_load!`** はテストでは絶対呼ばない (`from_rails_application` 経由でのみ実行)
- **gemspec の files exclude** ([exwiw.gemspec:29](exwiw.gemspec:29)) は `spec/` を除外しているため fixture が gem に同梱されない。dev only で OK
- **CHANGELOG**: Unreleased に「Refactor schema:generate (fail-fast on multi-DB) + STI belongs_to fix」を 1 行
