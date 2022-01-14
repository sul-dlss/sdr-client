# frozen_string_literal: true

module SdrClient
  module Deposit
    # Updates a DRO so that the structural metadata references the uploaded file ids
    class UpdateDroWithFileIdentifiers
      # @param [Cocina::Model::RequestDRO] request_dro for depositing
      # @param [Array<Files::DirectUploadResponse>] upload_responses the responses from uploading files
      # @returns [Cocina::Models::RequestDRO]
      def self.update(request_dro:, upload_responses:)
        # Manipulating request_dro as hash since immutable
        structural = request_dro.to_h[:structural]
        return request_dro.new({}) unless structural

        signed_ids = signed_id_map(upload_responses)
        request_dro.new(structural: updated_structural(structural, signed_ids))
      end

      def self.signed_id_map(upload_responses)
        upload_responses.to_h { |response| [response.filename, response.signed_id] }
      end
      private_class_method :signed_id_map

      def self.updated_structural(structural, signed_ids)
        structural[:contains].each do |file_set|
          file_set[:structural][:contains].each do |file|
            file[:externalIdentifier] = signed_ids[file[:filename]]
          end
        end
        structural
      end
      private_class_method :updated_structural
    end
  end
end
