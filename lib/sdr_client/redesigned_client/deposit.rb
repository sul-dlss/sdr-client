# frozen_string_literal: true

module SdrClient
  class RedesignedClient
    # Deposit into the SDR API
    class Deposit
      def self.deposit_model(...)
        new(...).deposit_model
      end

      # @param [Cocina::Model::RequestDRO] model for depositing
      # @param [Boolean] accession should the accessionWF be started
      # @param [String] basepath filepath to which filepaths are relative
      # @param [Array<String>] files a list of relative filepaths to upload
      # @param [Hash] options optional parameters
      # @option options [Boolean] assign_doi should a DOI be assigned to this item
      # @option options [Hash<String,String>] filepath_map map of relative filepaths to absolute filepaths
      # @option options [String] priority what processing priority should be used ('low', 'default')
      # @option options [String] user_versions action (none, new, update) to take for user version when closing version
      # @option options [String] grouping_strategy what strategy will be used to group files
      # @option options [String] file_set_strategy what strategy will be used to group file sets
      # @option options [RequestBuilder] request_builder a request builder instance
      def initialize(model:, accession:, basepath:, files: [], **options)
        @model = model
        @accession = accession
        @basepath = basepath
        @files = files
        @options = options
      end

      def deposit_model # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        check_files_exist!
        child_files_match! unless options[:request_builder]

        file_metadata = UploadFilesMetadataBuilder.build(files: files, mime_types: mime_types,
                                                         basepath: basepath, filepath_map: filepath_map)
        upload_responses = UploadFiles.upload(file_metadata: file_metadata,
                                              filepath_map: filepath_map)
        if options[:request_builder]
          @model = StructuralGrouper.group(
            request_builder: options[:request_builder],
            upload_responses: upload_responses,
            grouping_strategy: options[:grouping_strategy],
            file_set_strategy: options[:file_set_strategy]
          )
          child_files_match!
        end

        new_request_dro = UpdateDroWithFileIdentifiers.update(request_dro: model,
                                                              upload_responses: upload_responses)
        CreateResource.run(accession: accession,
                           priority: options[:priority],
                           assign_doi: options[:assign_doi],
                           user_versions: options[:user_versions],
                           metadata: new_request_dro)
      end

      private

      attr_reader :model, :files, :basepath, :accession, :options

      def check_files_exist!
        SdrClient::RedesignedClient.config.logger.info('checking to see if files exist')
        files.each do |filepath|
          absolute_filepath = absolute_filepath_for(filepath)
          next if ::File.exist?(absolute_filepath)

          # raise Errno::ENOENT, absolute_filepath
          raise "Filepath not found: #{filepath} (absolute path: #{absolute_filepath}) (filemath map: #{filepath_map})"
        end
      end

      def child_files_match! # rubocop:disable Metrics/AbcSize
        # Files without request files.
        files.each do |filepath|
          raise "Request file not provided for #{filepath}" if request_files[filepath].nil?
        end

        SdrClient::RedesignedClient.config.logger.info("request files: #{request_files.keys}")
        SdrClient::RedesignedClient.config.logger.info("files: #{files}")
        # Request files without files
        request_files.each_key do |request_filename|
          raise "File not provided for request file #{request_filename}" unless files.include?(request_filename)
        end
      end

      # Map of relative filepaths to mimetypes
      def mime_types
        return mime_types_from_request_builder if options[:request_builder]

        request_files.transform_values { |file| file.hasMimeType || 'application/octet-stream' }
      end

      def mime_types_from_request_builder
        files.to_h do |filepath|
          [filepath, options[:request_builder].for(filepath)['mime_type']]
        end
      end

      # Map of absolute filepaths to Cocina::Models::RequestFiles
      def request_files
        @request_files ||=
          if model.respond_to?(:structural) && model.structural
            model.structural.contains.map do |file_set|
              file_set.structural.contains.map do |file|
                [file.filename, file]
              end
            end.flatten(1).to_h
          else
            {}
          end
      end

      def absolute_filepath_for(filename)
        filepath_map.fetch(filename)
      end

      def filepath_map
        @filepath_map ||= options[:filepath_map] || files.each_with_object({}) do |filepath, obj|
          obj[filepath] = ::File.join(basepath, filename)
        end
      end
    end
  end
end
