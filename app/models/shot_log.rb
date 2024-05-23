class ShotLog < ApplicationRecord
  acts_as_paranoid
  belongs_to :user
  belongs_to :shot_position

  validates :user_id, presence: true
  validates :shot_position_id, presence: true
  validates :shot_at, presence: true
  validates :try_count, numericality: { greater_than_or_equal_to: 0 }
  validates :made_count, numericality: { greater_than_or_equal_to: 0 }
  validate :made_count_cannot_be_greater_than_try_count

  def self.summaries_for_line_graph_by_try_count(user, count_type: :thousand, shot_position_ids: nil)
    

  end

  def self.summaries_by_category_for_period(user, start_date, period_type: :day, length: 30)
    shot_positions_with_category = ShotPosition.select(:id, :category, :name)
    summaries = {}
    shot_positions_with_category.each do |position|
      summaries[position.category] ||= { total_tries: 0, total_mades: 0, shot_positions: [] }
      position_summaries = summaries_for_period(user, start_date, period_type: period_type, length: length,
                                                                  shot_position_ids: [position.id])
      total_tries = position_summaries.sum(&:total_tries)
      total_mades = position_summaries.sum(&:total_mades)
      success_rate = total_tries > 0 ? (total_mades.to_f / total_tries * 100).round(2) : 0
      summaries[position.category][:total_tries] += total_tries
      summaries[position.category][:total_mades] += total_mades
      summaries[position.category][:shot_positions] << {
        position_id: position.id,
        position_name: position.name,
        position_display_name: display_name(position.name),
        total_tries: total_tries,
        total_mades: total_mades,
        success_rate: success_rate
      }
    end

    summaries.each do |_category, data|
      total_tries = data[:total_tries]
      total_mades = data[:total_mades]
      data[:success_rate] = total_tries > 0 ? (total_mades.to_f / total_tries * 100).round(2) : 0
    end

    summaries
  end

  def self.summaries_for_period(user, start_date, period_type: :day, length: 30, shot_position_ids: nil)
    case period_type
    when :day
      date_format = '%Y-%m-%d'
      period_end = start_date - length.days
    when :week
      date_format = '%x-%v'
      period_end = start_date - (length * 7).days
    when :month
      date_format = '%Y-%m'
      period_end = start_date.beginning_of_month - length.months
    when :year
      date_format = '%Y'
      period_end = start_date.beginning_of_year - length.years
    else
      raise ArgumentError, 'Invalid period type'
    end

    if shot_position_ids.present?
      query = where(user_id: user.id)
              .where(shot_at: period_end.beginning_of_day..start_date.end_of_day)
              .where(shot_position_id: shot_position_ids)
    end

    result = query.group("DATE_FORMAT(shot_at, '#{date_format}')")
                  .select(
                    "DATE_FORMAT(shot_at, '#{date_format}') as period_start,
                   SUM(try_count) as total_tries,
                   SUM(made_count) as total_mades,
                   ROUND(IF(SUM(try_count) > 0, (SUM(made_count) / SUM(try_count)) * 100, 0), 2) as success_rate"
                  )
                  .order('period_start ASC')

    # 週の場合、取得したデータに基づいて週の開始日を計算する
    if period_type == :week
      result.map do |summary|
        year, week_number = summary.period_start.split('-').map(&:to_i)
        start_of_week = Date.commercial(year, week_number, 1) # 週の最初の日（月曜日）を取得
        summary.period_start = start_of_week.strftime('%Y-%m-%d') # period_keyを週の開始日に置き換える
        summary
      end
    else
      result
    end
  end

  def self.summaries_for_line_graph(user, start_date, period_type: :thirty_days, length: 30, shot_position_ids: nil)
    days_per_period = case period_type
                      when :day
                        1
                      when :three_days
                        3
                      when :seven_days
                        7
                      when :thirty_days
                        30

                      else
                        raise ArgumentError, "Unsupported period type: #{period_type}"
                      end

    start_date = start_date.to_date - (length * days_per_period - 1).days

    summaries = []
    current_start_date = start_date
    last_success_rate = nil

    length.times do |_i|
      current_end_date = current_start_date + days_per_period.days - 1.day

      shot_logs = ShotLog.where(user_id: user.id)
                         .where(shot_at: current_start_date.beginning_of_day..current_end_date.end_of_day)
      shot_logs = shot_logs.where(shot_position_id: shot_position_ids) if shot_position_ids.present?

      result = shot_logs.select(
        "SUM(try_count) as total_tries,
         SUM(made_count) as total_mades"
      ).first

      total_tries = result.total_tries || 0
      total_mades = result.total_mades || 0
      success_rate = if total_tries > 0
                       last_success_rate = (total_mades.to_f / total_tries * 100).round(2)
                     else
                       last_success_rate || 0.0
                     end

      summaries << {
        period_start: current_end_date,
        period_end: current_start_date,
        total_tries: total_tries,
        total_mades: total_mades,
        success_rate: success_rate
      }

      current_start_date = current_end_date + 1.day
    end

    summaries
  end

  private

  def made_count_cannot_be_greater_than_try_count
    return if made_count.nil? || try_count.nil?

    return unless made_count > try_count

    errors.add(:made_count, 'cannot be greater than try count')
  end

  def self.display_name(position_name)
    translations = {
      'three_point_left_corner' => '3P左コーナー',
      'three_point_left_45_degree' => '3P左45度',
      'three_point_top' => '3Pトップ',
      'three_point_right_45_degree' => '3P右45度',
      'three_point_right_corner' => '3P右コーナー',
      'two_point_left_corner' => '2P左コーナー',
      'two_point_left_45_degree' => '2P左45度',
      'two_point_top' => '2Pトップ',
      'two_point_right_corner' => '2P右コーナー',
      'two_point_right_45_degree' => '2P右45度',
      'free_throw' => 'フリースロー'
    }

    translations[position_name]
  end
end
