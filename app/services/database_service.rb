# frozen_string_literal: true

# Service class to handle database connection checks
class DatabaseService
  class << self
    def check_connections
      check_redis_connection
      check_postgres_connection
    rescue StandardError => e
      Rails.logger.error "Database connection failed: #{e.message}"
      raise
    end

    private

    def check_redis_connection
      RedisConn.current.ping
    end

    def check_postgres_connection
      ActiveRecord::Base.connection.execute('SELECT 1')
    end
  end
end
