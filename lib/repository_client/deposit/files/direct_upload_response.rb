# frozen_string_literal: true

module RepositoryClient
  module Deposit
    module Files
      DirectUploadResponse = Struct.new(:checksum, :byte_size, :content_type,
                                        :file_name, :signed_id, keyword_init: true)
    end
  end
end
