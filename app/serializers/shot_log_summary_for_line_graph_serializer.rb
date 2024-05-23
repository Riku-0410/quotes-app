class ShotLogSummaryForLineGraphSerializer < ApplicationSerializer
  attributes :date, :total_tries, :total_mades, :success_rate

  def date
    object.period_start
  end
end
