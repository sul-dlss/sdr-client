# frozen_string_literal: true

require 'logger'

module SdrClient
  # The namespace for the "get" command
  module Find
    DRO_PATH = '/v1/resources/%<id>s'

    # Raised when find returns an unsuccessful response
    class Failed < StandardError; end

    # @raise [Failed] if the find operation fails
    # @return [String] JSON for the given Cocina object or an error
    def self.run(druid, url:, logger: Logger.new($stdout))
      connection = Connection.new(url: url)
      path = format(DRO_PATH, id: druid)
      logger.info("Retrieving metadata from: #{path}")
      response = connection.get(path)
      unless response.success?
        error_message = "There was an HTTP #{response.status} error making the request: #{response.body}"
        logger.error(error_message)
        raise Failed, error_message
      end
      response.body
    end
  end
end
