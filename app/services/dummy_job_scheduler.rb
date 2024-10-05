class DummyJobScheduler
  def call
    dj = DummyJob.new
    Delayed::Job.enqueue dj, run_at: Time.now.utc + 5
  end
end
