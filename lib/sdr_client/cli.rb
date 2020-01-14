# frozen_string_literal: true

module SdrClient
  # The command line interface
  module CLI
    def self.start(command, options)
      case command
      when 'deposit'
        SdrClient::Deposit.run(options)
      when 'login'
        status = SdrClient::Login.run(options)
        puts status.value if status.failure?
      else
        raise "Unknown command #{command}"
      end
    end
  end
end
