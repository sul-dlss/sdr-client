# frozen_string_literal: true

require 'timeout'

module SdrClient
  class RedesignedClient
    # Wraps operations waiting for results from jobs
    class JobStatus
      attr_reader :result

      def initialize(job_id:)
        @job_id = job_id
        @result = {
          status: 'not started',
          output: {
            errors: nil,
            druid: ''
          }
        }
      end

      def complete?
        @result = client.get(path: path)
        @result[:status] == 'complete'
      end

      def druid
        @result[:output][:druid]
      end

      def errors
        @result[:output][:errors]
      end

      # Polls using exponential backoff, so as not to overrwhelm the server.
      # @param [Float] secs_between_requests (3.0) initially, how many secs between polling requests
      # @param [Integer] timeout_in_secs (180) timeout after this many secs
      # @param [Float] backoff_factor (2.0) how quickly to backoff. This should be > 1.0 and probably ought to be <= 2.0
      # @return [Boolean] true if successful false if unsuccessful.
      def wait_until_complete(secs_between_requests: 3.0, # rubocop:disable Metrics/MethodLength
                              timeout_in_secs: 180,
                              backoff_factor: 2.0,
                              max_secs_between_requests: 60)
        begin
          Timeout.timeout(timeout_in_secs) do
            loop do
              break if complete?

              yield if block_given?

              sleep(secs_between_requests)
              # Exponential backoff, limited to max_secs_between_requests
              secs_between_requests = [secs_between_requests * backoff_factor, max_secs_between_requests].min
            end
          end
        rescue Timeout::Error
          @result[:output][:errors] = ["Not complete after #{timeout_in_secs} seconds"]
        end

        errors.nil?
      end

      private

      attr_reader :job_id

      def client
        SdrClient::RedesignedClient.instance
      end

      def path
        "/v1/background_job_results/#{job_id}"
      end
    end
  end
end
