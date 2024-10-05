class DummyJob
  def call
    Rails.logger.info("This is a dummy job at #{DateTime.now}")
  end
end
