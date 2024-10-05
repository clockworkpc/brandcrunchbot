class DummyJob
  def perform
    Rails.logger.info("This is a dummy job at #{DateTime.now}")
  rescue StandardError => e
    Rails.logger.error("DummyJob failed with error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end
end
