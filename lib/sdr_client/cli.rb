# frozen_string_literal: true

module SdrClient
  # The command line interface
  module CLI
    def self.start(command, options)
      case command
      when 'deposit'
        SdrClient::Deposit.run(options)
      when 'login'
        SdrClient::Login.run(options)
      else
        raise "Unknown command #{command}"
      end
    end
  end
end
