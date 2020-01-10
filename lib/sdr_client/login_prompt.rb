# frozen_string_literal: true

require 'io/console'

module SdrClient
  # The namespace for the "login" command
  module LoginPrompt
    def self.run
      print 'Email: '
      email = gets
      email.strip!
      print 'Password: '
      password = $stdin.noecho(&:gets)
      password.strip!
      puts
      { email: email, password: password }
    end
  end
end
