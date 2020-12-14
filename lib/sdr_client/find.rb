# frozen_string_literal: true

require 'logger'

module SdrClient
  # The namespace for the "get" command
  module Find
    DRO_PATH = '/v1/resources/%<id>s'
    # @return [String] job id for the background job result
    def self.run(druid, url:, logger: Logger.new(STDOUT))
      connection = Connection.new(url: url)
      path = format(DRO_PATH, id: druid)
      logger.info("Retrieving metadata from: #{path}")
      response = connection.get(path)
      response.body
    end
  end
end
