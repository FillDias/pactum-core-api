class Api::V1::AuthController < ApplicationController
  def register
    user = User.new(user_params)

    if user.save
      token = JwtService.encode(user_id: user.id)
      render json: { data: { user: user_json(user), token: token } }, status: :created
    else
      render json: { error: user.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def login
    user = User.find_by(email: params[:email]&.downcase)

    if user&.authenticate(params[:password])
      token = JwtService.encode(user_id: user.id)
      render json: { data: { user: user_json(user), token: token } }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def logout
    render json: { data: { message: "Logged out successfully" } }
  end

  private

  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def user_json(user)
    { id: user.id, name: user.name, email: user.email, created_at: user.created_at }
  end
end
