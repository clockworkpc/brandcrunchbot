require 'redis'
require 'time'

class ApiRateLimiter
  MAX_REQUESTS_PER_MINUTE = 60
  TIME_WINDOW = 60 # in seconds

  def initialize
    @redis = Redis.new(
      url: ENV.fetch('REDIS_URL', nil),
      ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    )
  end

  # This method tracks API calls and ensures rate limiting
  def limit_rate(api_method, **kwargs)
    key = 'godaddy_api_calls'
    current_count = @redis.get(key).to_i

    if current_count < MAX_REQUESTS_PER_MINUTE
      @redis.multi do
        @redis.incr(key)
        @redis.expire(key, TIME_WINDOW) if current_count.zero?
      end

      # Pass keyword arguments when calling the method
      api_method.call(**kwargs)
    else
      sleep_time = @redis.ttl(key)
      Rails.logger.info "Rate limit exceeded. Sleeping for #{sleep_time} seconds..."
      sleep(sleep_time)

      # Retry with the same arguments
      limit_rate(api_method, **kwargs)
    end
  end
end
