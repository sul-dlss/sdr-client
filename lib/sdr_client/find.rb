# frozen_string_literal: true

module SdrClient
  # The namespace for the "get" command
  module Find
    DRO_PATH = '/v1/resources/%<id>s'

    # @raise [Failed] if the find operation fails
    # @return [String] JSON for the given Cocina object or an error
    def self.run(druid, url:, logger: Logger.new($stdout))
      connection = Connection.new(url: url)
      path = format(DRO_PATH, id: druid)
      logger.info("Retrieving metadata from: #{path}")
      response = connection.get(path)
      return response.body if response.success?

      logger.error("There was an HTTP #{response.status} error making the request: #{response.body}")
      UnexpectedResponse.call(response)
    end
  end
end
