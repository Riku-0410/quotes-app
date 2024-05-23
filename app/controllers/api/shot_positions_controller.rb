module Api
  class ShotPositionsController < Api::ApplicationController

    def index
      shot_positions = ShotPosition.all
      render json: shot_positions, each_serializer: ShotPositionSerializer
    end

  end
end
