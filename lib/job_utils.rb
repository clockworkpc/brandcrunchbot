module JobUtils
  def self.job_queued?(job_class:, args:)
    Delayed::Job.where('handler LIKE ?', "%#{job_class.name}%").any? do |job|
      job_data = begin
        YAML.unsafe_load(job.handler).job_data
      rescue StandardError
        nil
      end
      job_data && job_data['arguments'] == args
    end
  end
end
