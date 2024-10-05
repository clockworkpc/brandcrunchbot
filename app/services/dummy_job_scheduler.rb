class DummyJobScheduler
  def call
    DummyJob.set(wait: 5.seconds).perform_later('World')
  end
end
