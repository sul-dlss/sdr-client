# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::UpdateResource do
  describe 'run' do
    subject(:request) do
      described_class.run(metadata: metadata, logger: logger, connection: connection)
    end

    let(:dro_hash) do
      {
        'externalIdentifier' => 'druid:gf123df7654',
        'access' => { 'access' => 'world' },
        'type' => 'http://cocina.sul.stanford.edu/models/book.jsonld',
        'version' => 2,
        'administrative' => { 'hasAdminPolicy' => 'druid:bc123df4567' },
        'identification' => { 'sourceId' => 'googlebooks:12345' },
        'label' => 'This is my object'
      }
    end
    let(:metadata) do
      Cocina::Models::DRO.new(dro_hash)
    end

    let(:logger) { instance_double(Logger, debug: true, info: true) }
    let(:connection) { instance_double(SdrClient::Connection) }
    let(:response) { instance_double(Faraday::Response, status: 200, body: '{"jobId":9}') }
    before do
      allow(connection).to receive(:put).and_return(response)
    end

    context 'when it is successful' do
      it { is_expected.to eq 9 }
    end

    context 'when there is an error' do
      let(:response) { instance_double(Faraday::Response, status: 422, body: 'broken') }

      it 'raises an error' do
        expect { request }.to raise_error 'unexpected response: 422 broken'
      end
    end
  end
end
