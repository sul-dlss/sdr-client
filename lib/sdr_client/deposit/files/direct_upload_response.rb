# frozen_string_literal: true

module SdrClient
  module Deposit
    module Files
      DirectUploadResponse = Struct.new(:id, :key, :checksum, :byte_size, :content_type,
                                        :filename, :metadata, :created_at, :direct_upload,
                                        :signed_id, :service_name, keyword_init: true)
    end
  end
end
