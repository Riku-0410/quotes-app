module Api
  class ApplicationController < ActionController::Base
    class AuthenticationError < StandardError; end
    rescue_from AuthenticationError, with: :not_authenticated

    def authenticate
      validator = FirebaseAuthenticator.new(request.headers["Authorization"]&.split&.last)
      payload = validator.validate!
      puts 'payload_user_id'
      puts payload["user_id"]
      raise AuthenticationError unless current_user(payload["user_id"])
    end

    def current_user(user_id = nil)
      @current_user ||= User.find_by(user_id: user_id)
    end

    private
    def not_authenticated
      render json: { error: { messages: ["ログインしてください"] } }, status: :unauthorized
    end
  end
end
