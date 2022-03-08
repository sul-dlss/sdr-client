# frozen_string_literal: true

module SdrClient
  # The namespace for the "update" command
  module Update
    # @return [String] job id for the background job result
    def self.run(druid, apo:, url:, logger: Logger.new($stdout))
      cocina_item = Cocina::Models.build(
        JSON.parse(
          SdrClient::Find.run(druid, url: url)
        )
      )

      SdrClient::Deposit::UpdateResource.run(
        metadata: cocina_item.new(
          administrative: cocina_item.administrative.new(
            hasAdminPolicy: apo
          )
        ),
        logger: logger,
        connection: Connection.new(url: url)
      )
    end
  end
end
