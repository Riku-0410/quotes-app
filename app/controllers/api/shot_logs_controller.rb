module Api
  class ShotLogsController < Api::ApplicationController
    before_action :authenticate

    def show
      shot_log = current_user.shot_logs.find(params[:id])
      render json: shot_log, serializer: ShotLogSerializer
    end

    def update
      shot_log = current_user.shot_logs.find(params[:id])
      if shot_log.update(shot_log_params)
        render json: shot_log, serializer: ShotLogSerializer
      else
        render json: { errors: @shot_log.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      shot_log = current_user.shot_logs.find(params[:id])
      if shot_log.destroy
        render json: {}
      else
        render json: { errors: shot_log.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def summaries_for_line_graph_by_try_count
    end

    def summaries_for_line_graph
      raw_summaries = ShotLog.summaries_for_line_graph(
        current_user,
        params[:start_date].to_date,
        period_type: params[:period_type]&.to_sym || :day,
        length: params[:length].to_i || 30,
        shot_position_ids: params[:shot_position_ids]
      )

      summaries = raw_summaries.map do |summary|
        SerializerModel::ShotLogSummaryForLineGraph.new(summary)
      end
      render json: summaries, each_serializer: ShotLogSummaryForLineGraphSerializer
    rescue ArgumentError => e
      render json: { error: e.message }, status: :bad_request
    end

    def position_summaries
      start_date = params[:start_date].to_date
      period_type = params[:period_type]&.to_sym || :day
      length = params[:length] || 30

      summaries = ShotLog.summaries_by_category_for_period(
        current_user,
        start_date,
        period_type: period_type,
        length: length.to_i
      ).map do |category, data|
        {
          category_name: category || 'unknown',
          category_display_name: self.class.display_name(category) || 'unknown',
          total_tries: data[:total_tries],
          total_mades: data[:total_mades],
          success_rate: data[:success_rate],
          shot_positions: data[:shot_positions]
        }
      end

      render json: summaries
    end

    def by_date
      selected_date = params[:selected_date]
      shot_logs = current_user.shot_logs.where(shot_at: selected_date.to_date.beginning_of_day..selected_date.to_date.end_of_day).order(updated_at: :desc)
      render json: shot_logs, each_serializer: ShotLogSerializer
    end

    def create
      shot_log = current_user.shot_logs.build(shot_log_params)

      if shot_log.save
        render json: shot_log
      else
        render json: shot_log.errors
      end
    end

    private

    def shot_log_params
      params.require(:shot_log).permit(:shot_position_id, :try_count, :made_count, :shot_at)
    end

    def self.display_name(category_name)
      translations = {
        'three_point' => '3P全体',
        'two_point' => '2P全体'
      }

      translations[category_name]
    end
  end
end
