# frozen_string_literal: true

require 'json'

module SdrClient
  # API calls around background job results from dor-services-app
  module BackgroundJobResults
    # Get status/result of a background job
    # @param url [String] url for the service
    # @param job_id [String] required string representing a job identifier
    # @return [Hash] result of background job
    def self.show(url:, job_id:)
      connection = Connection.new(url: "#{url}/v1/background_job_results/#{job_id}").connection
      resp = connection.get

      raise "unexpected response: #{resp.status} #{resp.body}" unless resp.success?

      JSON.parse(resp.body).with_indifferent_access
    end
  end
end
