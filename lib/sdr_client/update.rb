# frozen_string_literal: true

module SdrClient
  # The namespace for the "update" command
  class Update
    # @return [String] job id for the background job result
    def self.run(druid, **options)
      new(druid, **options).run
    end

    def initialize(druid, **options)
      @druid = druid
      @url = options.fetch(:url)
      @options = options
    end

    # @return [String] job id for the background job result
    def run
      SdrClient::Deposit::UpdateResource.run(
        metadata: updated_cocina_item,
        logger: options[:logger] || Logger.new($stdout),
        connection: SdrClient::Connection.new(url: url)
      )
    end

    private

    attr_reader :druid, :logger, :options, :url

    def updated_cocina_item
      @updated_cocina_item ||=
        original_cocina_item.then { |cocina_item| update_apo(cocina_item) }
                            .then { |cocina_item| update_collection(cocina_item) }
                            .then { |cocina_item| update_copyright(cocina_item) }
                            .then { |cocina_item| update_use_and_reproduction(cocina_item) }
                            .then { |cocina_item| update_license(cocina_item) }
    end

    def original_cocina_item
      Cocina::Models.build(
        JSON.parse(
          SdrClient::Find.run(druid, url: url)
        )
      )
    end

    # Update the APO of a Cocina item if the options specify a new one, else return the original
    def update_apo(cocina_item)
      return cocina_item unless options[:apo]

      cocina_item.new(
        administrative: cocina_item.administrative.new(
          hasAdminPolicy: options[:apo]
        )
      )
    end

    # Update the collection of a Cocina item if the options specify a new one, else return the original
    def update_collection(cocina_item)
      return cocina_item unless options[:collection]

      cocina_item.new(
        structural: cocina_item.structural.new(
          isMemberOf: Array(options[:collection])
        )
      )
    end

    # Update the copyright of a Cocina item if the options specify a new one, else return the original
    def update_copyright(cocina_item)
      return cocina_item unless options[:copyright]

      cocina_item.new(
        access: cocina_item.access.new(
          copyright: options[:copyright]
        )
      )
    end

    # Update the use_and_reproduction of a Cocina item if the options specify a new one, else return the original
    def update_use_and_reproduction(cocina_item)
      return cocina_item unless options[:use_and_reproduction]

      cocina_item.new(
        access: cocina_item.access.new(
          useAndReproductionStatement: options[:use_and_reproduction]
        )
      )
    end

    # Update the license of a Cocina item if the options specify a new one, else return the original
    def update_license(cocina_item)
      return cocina_item unless options[:license]

      cocina_item.new(
        access: cocina_item.access.new(
          license: options[:license]
        )
      )
    end
  end
end
