# frozen_string_literal: true

RSpec.describe SdrClient::Login do
  describe '.run' do
    let(:login) do
      class_double(SdrClient::LoginPrompt, run: { email: 'foo@bar.io', password: '12345' })
    end

    subject { described_class.run(url: 'http://example.com/', login_service: login) }

    before do
      allow(SdrClient::Credentials).to receive(:write)
    end

    context 'when the login is successful' do
      let(:body) do
        '{"token":"zaa","exp":"2020-04-19"}'
      end

      before do
        stub_request(:post, 'http://example.com//v1/auth/login')
          .with(
            body: '{"email":"foo@bar.io","password":"12345"}'
          )
          .to_return(status: 200, body: body, headers: {})
      end

      it 'writes out the token' do
        expect(subject).to be_success
        expect(SdrClient::Credentials).to have_received(:write).with(body)
      end
    end

    context 'when the login is not successful' do
      before do
        stub_request(:post, 'http://example.com//v1/auth/login')
          .with(
            body: '{"email":"foo@bar.io","password":"12345"}'
          )
          .to_return(status: 400)
      end

      it 'returns a failure' do
        expect(subject).to be_failure
        expect(SdrClient::Credentials).not_to have_received(:write)
      end
    end
  end
end
