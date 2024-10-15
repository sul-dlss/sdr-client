# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::UpdateResource do
  describe 'run' do
    subject(:request) do
      described_class.run(metadata: metadata, logger: logger, connection: connection,
                          version_description: 'Updated metadata', user_versions: 'new')
    end

    let(:dro_hash) do
      {
        'externalIdentifier' => 'druid:gf123df7654',
        'access' => { 'view' => 'world', 'download' => 'world' },
        'type' => Cocina::Models::ObjectType.book,
        'version' => 2,
        'description' => {
          'title' => [{ 'value' => 'This is my object' }],
          'purl' => 'https://purl.stanford.edu/gf123df7654'
        },
        'administrative' => { 'hasAdminPolicy' => 'druid:bc123df4567' },
        'identification' => { 'sourceId' => 'googlebooks:12345' },
        'label' => 'This is my object',
        'structural' => {}
      }
    end
    let(:metadata) do
      Cocina::Models::DRO.new(dro_hash)
    end

    let(:logger) { instance_double(Logger, debug: true, info: true) }
    let(:connection) { SdrClient::Connection.new(url: 'https://sdr-api-prod.stanford.edu') }

    context 'when it is successful' do
      before do
        stub_request(:put, 'https://sdr-api-prod.stanford.edu/v1/resources/druid:gf123df7654?versionDescription=Updated%20metadata&user_versions=new&accession=true')
          .with(
            body: metadata.to_json
          )
          .to_return(status: 202, body: '{"jobId":9}')
      end

      it { is_expected.to eq 9 }
    end

    context 'when there is an error' do
      before do
        stub_request(:put, 'https://sdr-api-prod.stanford.edu/v1/resources/druid:gf123df7654?versionDescription=Updated%20metadata&user_versions=new&accession=true')
          .with(
            body: metadata.to_json
          )
          .to_return(status: 422, body: 'broken')
      end

      let(:response) { instance_double(Faraday::Response, status: 422, body: 'broken') }

      it 'raises an error' do
        expect { request }.to raise_error 'unexpected response: 422 broken'
      end
    end
  end
end
