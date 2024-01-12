# frozen_string_literal: true

# See login_spec.rb for examples
RSpec.describe SdrClient::RedesignedClient::Authenticator do
  let(:authenticator) { described_class.new }
  let(:url) { 'https://sdr-api.example.edu' }

  before do
    SdrClient::RedesignedClient.configure(
      email: 'testing@example.edu',
      password: 'password',
      url: url
    )
  end

  describe '.token' do
    before do
      allow(described_class).to receive(:new).and_return(authenticator)
      allow(authenticator).to receive(:token)
    end

    it 'invokes #token on a new instance' do
      described_class.token
      expect(authenticator).to have_received(:token).once
    end
  end

  describe '#token' do
    context 'when successful' do
      let(:login_response) do
        {
          token: 'a_long_silly_token',
          exp: 24.hours.from_now
        }
      end

      before do
        stub_request(:post, "#{url}/v1/auth/login")
          .to_return(status: 200, body: login_response.to_json, headers: {})
      end

      it 'returns the token parsed from the response' do
        expect(authenticator.token).to eq 'a_long_silly_token'
      end
    end

    context 'when unsuccessful' do
      let(:login_response) do
        { error: 'unauthorized' }
      end

      before do
        stub_request(:post, "#{url}/v1/auth/login")
          .to_return(status: 401, body: login_response.to_json, headers: {})
      end

      it 'lets UnexpectedResponse take the wheel' do
        expect { authenticator.token }.to raise_error(SdrClient::RedesignedClient::UnexpectedResponse::Unauthorized)
      end
    end
  end
end
