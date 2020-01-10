# frozen_string_literal: true

RSpec.describe SdrClient::Login do
  describe '.run' do
    let(:login) do
      class_double(SdrClient::LoginPrompt, run: { email: 'foo@bar.io', password: '12345' })
    end
    let(:body) do
      '{"token":"zaa","exp":"2020-04-19"}'
    end

    subject { described_class.run(url: 'http://example.com/', login_service: login) }

    before do
      stub_request(:post, 'http://example.com//v1/auth/login')
        .with(
          body: '{"email":"foo@bar.io","password":"12345"}'
        )
        .to_return(status: 200, body: body, headers: {})

      allow(SdrClient::Credentials).to receive(:write)
    end

    it 'writes out the token' do
      subject
      expect(SdrClient::Credentials).to have_received(:write).with(body)
    end
  end
end
