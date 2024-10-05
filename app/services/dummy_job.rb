class DummyJob < ApplicationJob
  queue_as :default

  def perform(string)
    Rails.logger.info("\n\nHello #{string}\n\nThis is a dummy job at #{DateTime.now}\n\n".green)
  rescue StandardError => e
    Rails.logger.error("\n\nDummyJob failed with error: #{e.message}\n\n".red)
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
