
require 'net/http'
class FirebaseAuthenticator
  class InvalidTokenError < StandardError; end

  ALG = 'RS256'
  CERTS_URI = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'
  CERTS_CACHE_KEY = 'firebase_auth_certificates'
  ISSUER_URI_BASE = 'https://securetoken.google.com/'

  def initialize(token)
    @token = token
  end

  def validate!
    project_id = ENV['FIREBASE_PROJECT_ID']
    raise 'FIREBASE_PROJECT_ID environment variable is not set' if project_id.nil?
    options = {
      algorithm: ALG,
      iss: ISSUER_URI_BASE + project_id,
      verify_iss: true,
      aud: project_id,
      verify_aud: true,
      verify_iat: true,
    }
    payload, _ = JWT.decode(@token, nil, true, options) do |header|
      cert = fetch_certificates[header['kid']]
      if cert.present?
        OpenSSL::X509::Certificate.new(cert).public_key
      else
        nil
      end
    end

    # JWT.decode でチェックされない項目のチェック
    raise InvalidTokenError.new('Invalid auth_time') unless Time.zone.at(payload['auth_time']).past?
    raise InvalidTokenError.new('Invalid sub') if payload['sub'].empty?

    payload
  rescue JWT::DecodeError => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")

    raise InvalidTokenError.new(e.message)
  end

  private

  def fetch_certificates


    cached = Rails.cache.read(CERTS_CACHE_KEY)
    return cached if cached.present?

    res = Net::HTTP.get_response(URI(CERTS_URI))
    raise 'Fetch certificates error' unless res.is_a?(Net::HTTPSuccess)

    body = JSON.parse(res.body)
    expires_at = Time.zone.parse(res.header['expires'])
    Rails.cache.write(CERTS_CACHE_KEY, body, expires_in: expires_at - Time.current)

    body
  end
end
