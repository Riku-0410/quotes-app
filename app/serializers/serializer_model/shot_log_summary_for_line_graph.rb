module SerializerModel
  class ShotLogSummaryForLineGraph < ActiveModelSerializers::Model
    attributes :period_start, :total_tries, :total_mades, :success_rate, :period_end

    def initialize(data)
      super(data)
      self.period_start = data[:period_start]
      self.total_tries = data[:total_tries]
      self.total_mades = data[:total_mades]
      self.success_rate = data[:success_rate]
      self.period_end = data[:period_end]
    end
  end
end
