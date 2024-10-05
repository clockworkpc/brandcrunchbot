class DummyJob
  def perform
    Rails.logger.info("This is a dummy job at #{DateTime.now}")
  end
end
