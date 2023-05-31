module SchedulingServicesHelper
  def self.ancillary_inputs_notice(ancillary_input_params)
    reports = ancillary_input_params.keys
                                    .select { |k| k.to_s.match?('report') }
                                    .map(&:titleize).join(', ')
    "To be refreshed soon: #{reports}"
  end

  def self.v4_inputs_notice(v4_input_params)
    inputs = v4_input_params.keys
                            .map(&:to_s).select { |k| k.match?('inputs') }
                            .map { |k1| k1.sub('_v5_inputs', '').titleize }.join(', ')
    "To be refreshed soon: #{inputs}"
  end

  def self.production_inputs_notice(production_input_params)
    inputs = production_input_params.keys
                                    .map(&:to_s).select { |k| k.match?('inputs') }
                                    .map { |k1| k1.sub('_inputs', '').titleize }.join(', ')
    "To be refreshed soon: #{inputs}"
  end

  def self.all_inputs_notice(all_input_params)
    inputs = all_input_params.keys
                             .map(&:to_s).select { |k| k.match?('inputs') }
                             .map { |k1| k1.sub('_inputs', '').titleize }.join(', ')
    "To be refreshed soon: #{inputs}"
  end
end
