# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::CreateResource do
  subject(:creator) { described_class }

  describe '.run' do
    let(:fake_instance) { instance_double(described_class, run: nil) }

    before do
      allow(described_class).to receive(:new).and_return(fake_instance)
    end

    it 'calls #run on a new instance' do
      described_class.run(
        accession: false,
        metadata: nil
      )
      expect(fake_instance).to have_received(:run).once
    end
  end

  describe '#run' do
    subject(:creator) { described_class.new(accession: false, metadata: model, user_versions: 'update') }

    let(:fake_connection) { instance_double(Faraday::Connection, post: fake_http_response) }
    let(:fake_http_response) do
      instance_double(Faraday::Response, status: fake_response_status, body: fake_response_body)
    end
    let(:fake_response_body) { { jobId: job_id }.to_json }
    let(:fake_response_status) { 201 }
    let(:job_id) { '123' }
    let(:model) { build(:request_dro) }

    before do
      SdrClient::RedesignedClient.configure(
        email: 'testing@example.edu',
        password: 'password',
        url: 'https://sdr-api.example.edu'
      )
      allow(SdrClient::RedesignedClient.instance).to receive(:connection).and_return(fake_connection)
      allow(SdrClient::RedesignedClient.config.logger).to receive(:info)
    end

    it 'posts the JSON to the API' do
      creator.run
      expect(fake_connection).to have_received(:post).once do |post|
        expect(post).to eq('/v1/resources?accession=false&user_versions=update')
      end
    end

    it 'logs the API response JSON' do
      creator.run
      expect(SdrClient::RedesignedClient.config.logger).to have_received(:info).with(
        "Response from server: #{fake_response_body}"
      )
    end

    it 'returns the job ID from the response JSON' do
      expect(creator.run).to eq(job_id)
    end

    context 'when post returns a status other than 201' do
      let(:fake_response_body) { { error: 'uh oh' } }
      let(:fake_response_status) { 500 }

      it 'uses UnexpectedResponse to deal with it' do
        expect { creator.run }.to raise_error(
          RuntimeError,
          "unexpected response: #{fake_response_status} #{fake_response_body}"
        )
      end
    end
  end
end
