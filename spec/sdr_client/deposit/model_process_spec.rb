# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::ModelProcess do
  let(:request_dro_hash) do
    {
      'access' => { 'access' => 'world' },
      'type' => 'http://cocina.sul.stanford.edu/models/book.jsonld',
      'version' => 1,
      'administrative' => { 'hasAdminPolicy' => 'druid:bc123df4567' },
      'identification' => { 'sourceId' => 'googlebooks:12345' },
      'structural' => {
        'isMemberOf' => ['druid:gh123df4567'],
        'contains' => [
          {
            'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            'label' => 'Page 1',
            'version' => 1,
            'structural' => {
              'contains' => [
                {
                  'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
                  'label' => 'file1.txt',
                  'filename' => 'file1.txt',
                  'access' => { 'access' => 'dark' },
                  'administrative' => { 'sdrPreserve' => false, 'shelve' => false },
                  'version' => 1,
                  'hasMessageDigests' => []
                }
              ]
            }
          },
          {
            'type' => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            'label' => 'Page 2',
            'version' => 1,
            'structural' => {
              'contains' => [
                {
                  'type' => 'http://cocina.sul.stanford.edu/models/file.jsonld',
                  'label' => 'file2.txt',
                  'filename' => 'file2.txt',
                  'access' => { 'access' => 'dark' },
                  'administrative' => { 'sdrPreserve' => false, 'shelve' => false },
                  'version' => 1,
                  'hasMessageDigests' => []
                }
              ]
            }
          }
        ]
      },
      'label' => 'This is my object'

    }
  end
  let(:request_dro) do
    Cocina::Models::RequestDRO.new(request_dro_hash)
  end

  let(:submitted_request_dro) do
    # When submitted, expect to have externalIdentifiers added.
    submitted_request_dro_hash = request_dro_hash.dup
    contains = submitted_request_dro_hash['structural']['contains']
    contains[0]['structural']['contains'][0]['externalIdentifier'] = 'BaHBLZz09Iiw'
    contains[1]['structural']['contains'][0]['externalIdentifier'] = 'dz09IiwiZXhwIjpudWxsLC'
    Cocina::Models::RequestDRO.new(submitted_request_dro_hash)
  end

  let(:connection) { SdrClient::Connection.new(url: 'http://example.com:3000', token: 'eyJhbGci') }
  let(:instance) do
    described_class.new(request_dro: request_dro,
                        connection: connection,
                        files: files,
                        accession: true)
  end

  describe '.run' do
    subject { instance.run }

    context 'when files do not exist' do
      let(:files) { ['file1.png', 'file2.png'] }

      it 'raises an error' do
        expect { subject }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when no request file for file' do
      let(:files) { ['spec/fixtures/file1.txt', 'spec/fixtures/file2.txt', 'spec/fixtures/file3.txt'] }

      it 'raises an error' do
        expect { subject }.to raise_error(/Request file not provided/)
      end
    end

    context 'when no file for request file' do
      let(:files) { ['spec/fixtures/file1.txt'] }

      it 'raises an error' do
        expect { subject }.to raise_error(/File not provided for request file/)
      end
    end

    context 'when files exist' do
      let(:files) { ['spec/fixtures/file1.txt', 'spec/fixtures/file2.txt'] }
      let(:upload_url1) { 'http://localhost:3000/v1/disk/GpscGFUTmxO' }
      let(:upload_url2) { 'http://localhost:3000/v1/disk/npoa1pIVjZP' }

      context 'when metadata upload succeeds' do
        before do
          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",'\
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",'\
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",'\
                             '"signed_id":"BaHBLZz09Iiw",'\
                             '"direct_upload":{"url":"' + upload_url1 + '",'\
                             '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",'\
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"file2.txt",'\
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":36,'\
                             '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",'\
                             '"signed_id":"dz09IiwiZXhwIjpudWxsLC",'\
                             '"direct_upload":{"url":"' + upload_url2 + '",'\
                             '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:put, upload_url1)
            .with(
              body: "This is a fixture file ...\n",
              headers: {
                'Content-Length' => '27',
                'Content-Type' => 'application/octet-stream'
              }
            )
            .to_return(status: 204)

          stub_request(:put, upload_url2)
            .with(
              body: "This is a fixture file for testing.\n",
              headers: {
                'Content-Length' => '36',
                'Content-Type' => 'application/octet-stream'
              }
            )
            .to_return(status: 204)

          stub_request(:post, 'http://example.com:3000/v1/resources?accession=true')
            .with(
              body: submitted_request_dro.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 201, body: '{"jobId":"1"}',
                       headers: { 'Location' => 'http://example.com/background_job/1' })
        end

        it 'uploads files' do
          expect(subject).to eq('1')
        end
      end

      context 'when metadata upload fails with bad request' do
        before do
          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",'\
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",'\
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",'\
                             '"signed_id":"BaHBLZz09Iiw",'\
                             '"direct_upload":{"url":"' + upload_url1 + '",'\
                             '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",'\
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"file2.txt",'\
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":36,'\
                             '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",'\
                             '"signed_id":"dz09IiwiZXhwIjpudWxsLC",'\
                             '"direct_upload":{"url":"' + upload_url2 + '",'\
                             '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:put, upload_url1)
            .with(
              body: "This is a fixture file ...\n",
              headers: {
                'Content-Length' => '27',
                'Content-Type' => 'application/octet-stream'
              }
            )
            .to_return(status: 204)

          stub_request(:put, upload_url2)
            .with(
              body: "This is a fixture file for testing.\n",
              headers: {
                'Content-Length' => '36',
                'Content-Type' => 'application/octet-stream'
              }
            )
            .to_return(status: 204)

          stub_request(:post, 'http://example.com:3000/v1/resources?accession=true')
            .to_return(status: 400, body: '{"id":"bad_request",' \
              '"message":"#/components/schemas/DROStructural missing required parameters: isMemberOf"}')
        end

        it 'uploads files' do
          expect { subject }.to raise_error(/There was an error with your request/)
        end
      end

      context 'when metadata upload fails with unauthorized' do
        before do
          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",'\
                '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",'\
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",'\
                             '"signed_id":"BaHBLZz09Iiw",'\
                             '"direct_upload":{"url":"' + upload_url1 + '",'\
                             '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",'\
                '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"file2.txt",'\
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":36,'\
                             '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",'\
                             '"signed_id":"dz09IiwiZXhwIjpudWxsLC",'\
                             '"direct_upload":{"url":"' + upload_url2 + '",'\
                             '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:put, upload_url1)
            .with(
              body: "This is a fixture file ...\n",
              headers: {
                'Content-Length' => '27',
                'Content-Type' => 'application/octet-stream'
              }
            )
            .to_return(status: 204)

          stub_request(:put, upload_url2)
            .with(
              body: "This is a fixture file for testing.\n",
              headers: {
                'Content-Length' => '36',
                'Content-Type' => 'application/octet-stream'
              }
            )
            .to_return(status: 204)

          stub_request(:post, 'http://example.com:3000/v1/resources?accession=true')
            .to_return(status: 401)
        end

        it 'uploads files' do
          expect { subject }.to raise_error(/There was an error with your credentials./)
        end
      end
    end

    context 'when no structural' do
      let(:request_dro_hash) do
        {
          'access' => { 'access' => 'world' },
          'type' => 'http://cocina.sul.stanford.edu/models/book.jsonld',
          'version' => 1,
          'administrative' => { 'hasAdminPolicy' => 'druid:bc123df4567' },
          'identification' => { 'sourceId' => 'googlebooks:12345' },
          'label' => 'This is my object'

        }
      end

      let(:files) { [] }

      before do
        stub_request(:post, 'http://example.com:3000/v1/resources?accession=true')
          .with(
            body: Cocina::Models::RequestDRO.new(request_dro_hash).to_json,
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Authorization' => 'Bearer eyJhbGci',
              'Content-Type' => 'application/json',
              'User-Agent' => /Faraday v1/
            }
          )
          .to_return(status: 201, body: '{"jobId":"1"}',
                     headers: { 'Location' => 'http://example.com/background_job/1' })
      end

      it 'uploads resource' do
        expect(subject).to eq('1')
      end
    end
  end
end
