# frozen_string_literal: true

module Exwiw
  module Adapter
    class SqliteAdapter < Base
      def execute(query)
        # 쿼리를 실행하고 결과를 반환하는 로직을 구현합니다.
        [] # 예시로 빈 배열 반환
      end

      def to_bulk_insert(results, table)
        # 결과를 bulk insert SQL로 변환하는 로직을 구현합니다.
        "INSERT INTO \\#{table.name} ..." # 예시로 간단한 문자열 반환
      end
    end
  end
end
