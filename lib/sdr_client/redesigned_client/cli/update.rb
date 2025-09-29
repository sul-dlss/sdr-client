# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    class CLI < Thor
      # Update a resource given command-line options
      class Update
        # @return [String] job id for the background job result
        def self.run(druid, **options)
          new(druid, **options).run
        end

        def initialize(druid, **options)
          @druid = druid
          @options = options
        end

        # @return [String] job id for the background job result
        def run
          client.update_model(model: updated_cocina_object)
        end

        private

        attr_reader :druid, :options

        def client
          SdrClient::RedesignedClient.instance
        end

        def updated_cocina_object
          @updated_cocina_object ||=
            original_cocina_object.then { |cocina_object| update_cocina(cocina_object) }
                                  .then { |cocina_object| update_apo(cocina_object) }
                                  .then { |cocina_object| update_collection(cocina_object) }
                                  .then { |cocina_object| update_copyright(cocina_object) }
                                  .then { |cocina_object| update_use_and_reproduction(cocina_object) }
                                  .then { |cocina_object| update_license(cocina_object) }
                                  .then { |cocina_object| update_access(cocina_object) }
        end

        def original_cocina_object
          Cocina::Models.build(
            client.find(object_id: druid)
          )
        end

        def cocina_hash_from_file
          @cocina_hash_from_file ||= JSON.parse(::File.read(options[:cocina_file]), symbolize_names: true)
        end

        def cocina_hash_from_pipe
          @cocina_hash_from_pipe ||= JSON.parse($stdin.read, symbolize_names: true)
        end

        # Update the Cocina in full
        def update_cocina(cocina_object)
          if options[:cocina_file]
            update_cocina_from_file(cocina_object)
          elsif options[:cocina_pipe]
            update_cocina_from_pipe(cocina_object)
          else
            cocina_object
          end
        end

        def update_cocina_from_file(cocina_object)
          if !::File.file?(options[:cocina_file]) || !::File.readable?(options[:cocina_file])
            raise "File not found: #{options[:cocina_file]}"
          end

          # NOTE: We may want to add more checks later. For now, make sure the identifiers match.
          if cocina_object.externalIdentifier != cocina_hash_from_file[:externalIdentifier]
            raise "Cocina in #{options[:cocina_file]} has a different external identifier " \
                  "than #{cocina_object.externalIdentifier}: #{cocina_hash_from_file[:externalIdentifier]}"
          end

          cocina_object.new(cocina_hash_from_file)
        end

        def update_cocina_from_pipe(cocina_object)
          raise 'No pipe provided' unless $stdin.stat.pipe?

          # NOTE: We may want to add more checks later. For now, make sure the identifiers match.
          if cocina_object.externalIdentifier != cocina_hash_from_pipe[:externalIdentifier]
            raise 'Cocina piped in has a different external identifier than ' \
                  "#{cocina_object.externalIdentifier}: #{cocina_hash_from_pipe[:externalIdentifier]}"
          end

          cocina_object.new(cocina_hash_from_pipe)
        end

        # Update the APO of a Cocina item if the options specify a new one, else return the original
        def update_apo(cocina_object)
          return cocina_object unless options[:apo]

          cocina_object.new(
            administrative: cocina_object.administrative.new(
              hasAdminPolicy: options[:apo]
            )
          )
        end

        # Update the collection of a Cocina item if the options specify a new one, else return the original
        def update_collection(cocina_object)
          return cocina_object unless options[:collection]

          cocina_object.new(
            structural: cocina_object.structural.new(
              isMemberOf: Array(options[:collection])
            )
          )
        end

        # Update the copyright of a Cocina item if the options specify a new one, else return the original
        def update_copyright(cocina_object)
          return cocina_object unless options[:copyright]

          cocina_object.new(
            access: cocina_object.access.new(
              copyright: options[:copyright]
            )
          )
        end

        # Update the use and reproduction statement of a Cocina item if the
        # options specify a new one, else return the original
        def update_use_and_reproduction(cocina_object)
          return cocina_object unless options[:use_and_reproduction]

          cocina_object.new(
            access: cocina_object.access.new(
              useAndReproductionStatement: options[:use_and_reproduction]
            )
          )
        end

        # Update the license of a Cocina item if the options specify a new one, else return the original
        def update_license(cocina_object)
          return cocina_object unless options[:license]

          cocina_object.new(
            access: cocina_object.access.new(
              license: options[:license]
            )
          )
        end

        # Update the access of a Cocina item if the options specify a new one, else return the original
        def update_access(cocina_object)
          return cocina_object unless options[:view] || options[:download] || options[:location] || options[:cdl]

          cocina_object.new(
            access: cocina_object.access.new(
              view: options[:view],
              download: options[:download],
              location: options[:location],
              controlledDigitalLending: !!options[:cdl]
            ),
            structural: cocina_object.structural.new(
              contains: cocina_object.structural.contains.map do |file_set|
                file_set.new(
                  structural: file_set.structural.new(
                    contains: file_set.structural.contains.map do |file|
                      file.new(
                        access: file.access.new(
                          view: options[:view],
                          download: options[:download],
                          location: options[:location],
                          controlledDigitalLending: !!options[:cdl]
                        ),
                        administrative: options[:view] == 'dark' ?
                          { publish: false, shelve: false, sdrPreserve: file.administrative.sdrPreserve } :
                          file.administrative
                      )
                    end
                  )
                )
              end
            )
          )
        end
      end
    end
  end
end
