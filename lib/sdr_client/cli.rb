# frozen_string_literal: true

module SdrClient
  # The command line interface
  module CLI
    def self.start(command, options)
      case command
      when 'deposit'
        SdrClient::Deposit.run(options)
      end
    end
  end
end
