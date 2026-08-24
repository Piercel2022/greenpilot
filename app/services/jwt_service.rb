class JwtService
  ALGORITHM = "HS256"
  EXPIRATION = 24.hours

  class Error < StandardError
  end

  def self.encode(user)
    now = Time.current.to_i

    payload = {
      sub: user.id,
      iat: now,
      exp: now + EXPIRATION.to_i
    }

    JWT.encode(
      payload,
      Rails.application.secret_key_base,
      ALGORITHM
    )
  end

  def self.decode(token)
    payload, = JWT.decode(
      token,
      Rails.application.secret_key_base,
      true,
      {
        algorithm: ALGORITHM
      }
    )

    payload
  rescue JWT::ExpiredSignature
    raise Error, "Token expired"
  rescue JWT::DecodeError
    raise Error, "Invalid token"
  end
end