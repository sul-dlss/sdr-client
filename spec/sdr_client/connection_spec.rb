# frozen_string_literal: true

RSpec.describe SdrClient::Connection do
  subject(:conn) { described_class.new(url: 'http://example.com/', token: 'foobar') }

  describe '#proxy' do
    subject { conn.proxy('jane@stanford.edu') }

    context 'when the login is successful' do
      let(:body) do
        '{"token":"zaa","exp":"2020-04-19"}'
      end

      before do
        stub_request(:post, 'http://example.com/v1/auth/proxy?to=jane@stanford.edu')
          .with(
            headers: { 'Authorization' => 'Bearer foobar' }
          )
          .to_return(status: 200, body: body, headers: {})
      end

      it 'writes out the token' do
        expect(subject).to be_success
        expect(subject.value!).to eq body
      end
    end

    context 'when the login is not successful' do
      before do
        stub_request(:post, 'http://example.com/v1/auth/proxy?to=jane@stanford.edu')
          .with(
            headers: { 'Authorization' => 'Bearer foobar' }
          )
          .to_return(status: 400)
      end

      it 'returns a failure' do
        expect(subject).to be_failure
      end
    end
  end
end
