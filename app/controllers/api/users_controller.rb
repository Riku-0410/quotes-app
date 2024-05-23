module Api
  class UsersController < Api::ApplicationController

    def create
      user = User.new(user_params)
      if user.save
        render json: user, serializer: UserSerializer
      else
        render json: user.errors
      end
    end

    private

    def user_params
      params.require(:user).permit(:user_id, :email)
    end
  end
end
