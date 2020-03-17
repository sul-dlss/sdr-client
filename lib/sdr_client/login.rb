# frozen_string_literal: true

module SdrClient
  # The namespace for the "login" command
  module Login
    LOGIN_PATH = '/v1/auth/login'
    extend Dry::Monads[:result]

    # @return [Result] the status of the call
    def self.run(url:, login_service: LoginPrompt, credential_store: Credentials)
      request_json = JSON.generate(login_service.run)
      response = Faraday.post(url + LOGIN_PATH, request_json, 'Content-Type' => 'application/json')
      case response.status
      when 200
        credential_store.write(response.body)
        Success()
      when 400
        Failure('Email address is not a valid email')
      when 401
        Failure('Invalid username or password')
      else
        Failure("Status: #{response.status}\n#{response.body}")
      end
    end
  end
end
