module DynamicLinksAnalytics
  class PerformanceStatsService
    def self.call
      new.call
    end

    def call
      return {} unless pg_stat_statements_available?

      {
        top_queries: top_queries,
        query_stats: query_statistics
      }
    end

    private

    def pg_stat_statements_available?
      @pg_stat_statements_available ||= begin
        ActiveRecord::Base.connection.execute(
          "SELECT 1 FROM pg_available_extensions WHERE name = 'pg_stat_statements' AND installed_version IS NOT NULL"
        ).any?
      rescue ActiveRecord::StatementInvalid
        false
      end
    end

    def top_queries(limit = 10)
      ActiveRecord::Base.connection.execute(<<~SQL.squish)
        SELECT query, calls, total_time, mean_time, rows
        FROM pg_stat_statements
        WHERE query LIKE '%dynamic_links_analytics%'
        ORDER BY total_time DESC
        LIMIT #{limit}
      SQL
    end

    def query_statistics
      result = ActiveRecord::Base.connection.execute(<<~SQL.squish)
        SELECT
          COUNT(*) as total_queries,
          SUM(calls) as total_calls,
          AVG(mean_time) as avg_execution_time,
          MAX(max_time) as max_execution_time
        FROM pg_stat_statements
        WHERE query LIKE '%dynamic_links_analytics%'
      SQL

      result.first&.symbolize_keys || {}
    end
  end
end
