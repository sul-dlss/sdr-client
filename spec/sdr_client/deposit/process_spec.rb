# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::Process do
  let(:metadata) do
    SdrClient::Deposit::Request.new(label: 'This is my object',
                                    type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                                    access: 'world',
                                    apo: 'druid:bc123df4567',
                                    collection: 'druid:gh123df4567',
                                    source_id: 'googlebooks:12345',
                                    files_metadata: files_metadata)
  end

  let(:connection) { SdrClient::Connection.new(url: 'http://example.com:3000', token: 'eyJhbGci') }
  let(:instance) do
    described_class.new(metadata: metadata,
                        connection: connection,
                        files: files,
                        logger: logger,
                        accession: false)
  end

  let(:logger) { instance_double(Logger, info: nil, debug: nil) }

  let(:files_metadata) { {} }

  describe '.run' do
    subject { instance.run }

    context 'when files do not exist' do
      let(:files) { ['file1.png', 'file2.png'] }

      it 'raises an error' do
        expect { subject }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when files exist' do
      let(:files) { ['spec/fixtures/file1.txt', 'spec/fixtures/file2.txt'] }
      let(:upload_url1) { 'http://localhost:3000/v1/disk/GpscGFUTmxO' }
      let(:upload_url2) { 'http://localhost:3000/v1/disk/npoa1pIVjZP' }
      before do
      end

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

          stub_request(:post, 'http://example.com:3000/v1/resources')
            .with(
              body: '{"type":"http://cocina.sul.stanford.edu/models/book.jsonld","label":"This is my object","version":1,"access":{"access":"world","download":"none"},"administrative":{"hasAdminPolicy":"druid:bc123df4567"},"identification":{"sourceId":"googlebooks:12345"},"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/fileset.jsonld","label":"Page 1","version":1,"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/file.jsonld","label":"file1.txt","filename":"file1.txt","version":1,"externalIdentifier":"BaHBLZz09Iiw","hasMessageDigests":[],"access":{"access":"world","download":"none"},"administrative":{"sdrPreserve":true,"shelve":true}}]}},{"type":"http://cocina.sul.stanford.edu/models/fileset.jsonld","label":"Page 2","version":1,"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/file.jsonld","label":"file2.txt","filename":"file2.txt","version":1,"externalIdentifier":"dz09IiwiZXhwIjpudWxsLC","hasMessageDigests":[],"access":{"access":"world","download":"none"},"administrative":{"sdrPreserve":true,"shelve":true}}]}}],"isMemberOf":"druid:gh123df4567"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 201, body: '{"jobId":"1"}',
                       headers: { 'Location' => 'http://example.com/background_job/1' })
        end

        it 'uploads files' do
          expect(subject).to eq('1')
        end
      end

      context 'when metadata upload succeeds with additional file metadata' do
        let(:files_metadata) do
          {
            'file1.txt' => {
              'md5' => 'abc123',
              'sha1' => 'def456',
              'mime_type' => 'image/tiff',
              'access' => 'dark',
              'preserve' => false,
              'shelve' => false
            }
          }
        end

        before do
          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",'\
                    '"content_type":"image/tiff"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",'\
                             '"content_type":"image/tiff","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",'\
                             '"signed_id":"BaHBLZz09Iiw",'\
                             '"direct_upload":{"url":"' + upload_url1 + '",'\
                             '"headers":{"Content-Type":"image/tiff"}}}',
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
                'Content-Type' => 'image/tiff'
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

          stub_request(:post, 'http://example.com:3000/v1/resources')
            .with(
              body: '{"type":"http://cocina.sul.stanford.edu/models/book.jsonld","label":"This is my object","version":1,"access":{"access":"world","download":"none"},"administrative":{"hasAdminPolicy":"druid:bc123df4567"},"identification":{"sourceId":"googlebooks:12345"},"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/fileset.jsonld","label":"Page 1","version":1,"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/file.jsonld","label":"file1.txt","filename":"file1.txt","version":1,"hasMimeType":"image/tiff","externalIdentifier":"BaHBLZz09Iiw","hasMessageDigests":[{"type":"md5","digest":"abc123"},{"type":"sha1","digest":"def456"}],"access":{"access":"dark","download":"none"},"administrative":{"sdrPreserve":false,"shelve":false}}]}},{"type":"http://cocina.sul.stanford.edu/models/fileset.jsonld","label":"Page 2","version":1,"structural":{"contains":[{"type":"http://cocina.sul.stanford.edu/models/file.jsonld","label":"file2.txt","filename":"file2.txt","version":1,"externalIdentifier":"dz09IiwiZXhwIjpudWxsLC","hasMessageDigests":[],"access":{"access":"world","download":"none"},"administrative":{"sdrPreserve":true,"shelve":true}}]}}],"isMemberOf":"druid:gh123df4567"}}',
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

          stub_request(:post, 'http://example.com:3000/v1/resources')
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

          stub_request(:post, 'http://example.com:3000/v1/resources')
            .to_return(status: 401)
        end

        it 'uploads files' do
          expect { subject }.to raise_error(/There was an error with your credentials./)
        end
      end
    end
  end
end
