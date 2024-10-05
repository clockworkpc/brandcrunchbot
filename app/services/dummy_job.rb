class DummyJob
  def perform
    Rails.logger.info("\n\nThis is a dummy job at #{DateTime.now}\n\n".green)
  rescue StandardError => e
    Rails.logger.error("\n\nDummyJob failed with error: #{e.message}\n\n".red)
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
