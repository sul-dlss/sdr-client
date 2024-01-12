# frozen_string_literal: true

require 'logger'

module SdrClient
  class RedesignedClient
    # Find an object
    class Find
      def self.run(...)
        new(...).run
      end

      # @param [String] object_id an ID for an object
      def initialize(object_id:)
        @object_id = object_id
      end

      # @raise [Failed] if the find operation fails
      # @return [String] JSON for the given Cocina object or an error
      def run
        logger.info("Retrieving metadata from: #{path}")
        client.get(path: path)
      end

      private

      attr_reader :object_id

      def logger
        SdrClient::RedesignedClient.config.logger
      end

      def client
        SdrClient::RedesignedClient.instance
      end

      def path
        format('/v1/resources/%<object_id>s', object_id: object_id)
      end
    end
  end
end
