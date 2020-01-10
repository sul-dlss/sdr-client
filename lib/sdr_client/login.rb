# frozen_string_literal: true

module SdrClient
  # The namespace for the "login" command
  module Login
    LOGIN_PATH = '/v1/auth/login'
    def self.run(url:, login_service: LoginPrompt)
      request_json = JSON.generate(login_service.run)
      response = Faraday.post(url + LOGIN_PATH, request_json, 'Content-Type' => 'application/json')
      case response.status
      when 200
        Credentials.write(response.body)
      when 400
        puts 'Email address is not a valid email'
      when 401
        puts 'Invalid username or password'
      else
        puts "Status: #{response.status}"
        puts response.body
      end
    end
  end
end
