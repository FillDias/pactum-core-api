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

  # Aceita token do pactum-api e retorna token do core-api
  # Cria o usuario no core-api automaticamente se nao existir
  def sync
    pactum_token = params[:pactum_token].to_s
    email        = params[:email].to_s.downcase

    return render json: { error: "Missing params" }, status: :bad_request if pactum_token.blank? || email.blank?

    user = User.find_by(email: email)

    if user.nil?
      temp_password = SecureRandom.hex(16)
      user = User.create!(
        name:     params[:name].presence || email.split("@").first,
        email:    email,
        password: temp_password
      )
    end

    token = JwtService.encode(user_id: user.id)
    render json: { data: { token: token } }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def user_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def user_json(user)
    { id: user.id, name: user.name, email: user.email, created_at: user.created_at }
  end
end
