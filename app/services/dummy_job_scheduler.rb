class DummyJobScheduler
  def call
    dj = DummyJob.new
    dj.delay(run_at: Time.now.utc + 5)
  end
end
