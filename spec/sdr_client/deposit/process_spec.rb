# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::Process do
  let(:metadata) do
    SdrClient::Deposit::Request.new(label: 'This is my object',
                                    type: Cocina::Models::ObjectType.book,
                                    view: 'world',
                                    download: 'none',
                                    apo: 'druid:hv992ry2431',
                                    collection: 'druid:gh123df4567',
                                    source_id: 'sul:1234',
                                    files_metadata: files_metadata)
  end

  let(:connection) { SdrClient::Connection.new(url: 'http://example.com:3000', token: 'eyJhbGci') }
  let(:accession) { false }
  let(:instance) do
    described_class.new(metadata: metadata,
                        connection: connection,
                        files: files,
                        basepath: basepath,
                        logger: logger,
                        accession: accession)
  end

  let(:logger) { instance_double(Logger, info: nil, debug: nil) }

  let(:files_metadata) { {} }

  let(:basepath) { 'spec/fixtures' }

  describe '.run' do
    subject { instance.run }

    context 'when files do not exist' do
      let(:files) { ['file1.png', 'file2.png'] }

      it 'raises an error' do
        expect { subject }.to raise_error(Errno::ENOENT)
      end
    end

    context 'when files exist' do
      let(:files) { ['file1.txt', 'dir1/file2.txt'] }
      let(:upload_url1) { 'http://localhost:3000/v1/disk/GpscGFUTmxO' }
      let(:upload_url2) { 'http://localhost:3000/v1/disk/npoa1pIVjZP' }

      let(:access) do
        {
          view: 'world',
          download: 'none'
        }
      end

      let(:structural) do
        {
          contains: [{
            type: Cocina::Models::FileSetType.file,
            label: 'Page 1',
            version: 1,
            structural: {
              contains: [{
                type: Cocina::Models::ObjectType.file,
                label: 'file1.txt',
                filename: 'file1.txt',
                version: 1,
                externalIdentifier: 'BaHBLZz09Iiw',
                hasMessageDigests: [],
                access: {
                  view: 'world',
                  download: 'none'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: true,
                  shelve: true
                }
              }]
            }
          }, {
            type: Cocina::Models::FileSetType.file,
            label: 'Page 2',
            version: 1,
            structural: {
              contains: [{
                type: Cocina::Models::ObjectType.file,
                label: 'file2.txt',
                filename: 'dir1/file2.txt',
                version: 1,
                externalIdentifier: 'dz09IiwiZXhwIjpudWxsLC',
                hasMessageDigests: [],
                access: {
                  view: 'world',
                  download: 'none'
                },
                administrative: {
                  publish: true,
                  sdrPreserve: true,
                  shelve: true
                }
              }]
            }
          }],
          hasMemberOrders: [],
          isMemberOf: ['druid:gh123df4567']
        }
      end

      let(:request_dro) do
        build(
          :request_dro, type: Cocina::Models::ObjectType.book, label: 'This is my object'
        ).new(
          access: access, structural: structural
        )
      end

      context 'when metadata upload succeeds' do
        before do
          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",' \
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",' \
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",' \
                             '"signed_id":"BaHBLZz09Iiw",' \
                             '"direct_upload":{"url":"' + upload_url1 + '",' \
                                                                        '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"dir1/file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",' \
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"dir1-file2.txt",' \
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":36,' \
                             '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",' \
                             '"signed_id":"dz09IiwiZXhwIjpudWxsLC",' \
                             '"direct_upload":{"url":"' + upload_url2 + '",' \
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

          stub_request(:post, "http://example.com:3000/v1/resources?accession=#{accession}")
            .with(body: request_dro.to_h.except(:description).to_json, headers: { 'Content-Type' => 'application/json' })
            .to_return(status: 201, body: '{"jobId":"1"}',
                       headers: { 'Location' => 'http://example.com/background_job/1' })
        end

        it 'uploads files' do
          expect(subject).to eq('1')
        end

        context 'when accession is true' do
          let(:accession) { true }

          it 'uploads files' do
            expect(subject).to eq('1')
          end
        end
      end

      context 'when metadata upload succeeds with additional file metadata' do
        let(:files_metadata) do
          {
            'file1.txt' => {
              'md5' => 'abc123',
              'sha1' => 'def456',
              'mime_type' => 'image/tiff',
              'view' => 'dark',
              'download' => 'none',
              'publish' => false,
              'preserve' => false,
              'shelve' => false
            }
          }
        end

        let(:access) do
          {
            view: 'world',
            download: 'none'
          }
        end

        let(:structural) do
          {
            contains: [{
              type: Cocina::Models::FileSetType.file,
              label: 'Page 1',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::ObjectType.file,
                  label: 'file1.txt',
                  filename: 'file1.txt',
                  version: 1,
                  hasMimeType: 'image/tiff',
                  externalIdentifier: 'BaHBLZz09Iiw',
                  hasMessageDigests: [{
                    type: 'md5',
                    digest: 'abc123'
                  }, {
                    type: 'sha1',
                    digest: 'def456'
                  }],
                  access: {
                    view: 'dark',
                    download: 'none'
                  },
                  administrative: {
                    publish: false,
                    sdrPreserve: false,
                    shelve: false
                  }
                }]
              }
            }, {
              type: Cocina::Models::FileSetType.file,
              label: 'Page 2',
              version: 1,
              structural: {
                contains: [{
                  type: Cocina::Models::ObjectType.file,
                  label: 'file2.txt',
                  filename: 'dir1/file2.txt',
                  version: 1,
                  externalIdentifier: 'dz09IiwiZXhwIjpudWxsLC',
                  hasMessageDigests: [],
                  access: {
                    view: 'world',
                    download: 'none'
                  },
                  administrative: {
                    publish: true,
                    sdrPreserve: true,
                    shelve: true
                  }
                }]
              }
            }],
            hasMemberOrders: [],
            isMemberOf: ['druid:gh123df4567']
          }
        end

        before do
          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",' \
                    '"content_type":"image/tiff"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",' \
                             '"content_type":"image/tiff","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",' \
                             '"signed_id":"BaHBLZz09Iiw",' \
                             '"direct_upload":{"url":"' + upload_url1 + '",' \
                                                                        '"headers":{"Content-Type":"image/tiff"}}}',
                       headers: {})

          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"dir1/file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",' \
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"dir1-file2.txt",' \
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":36,' \
                             '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",' \
                             '"signed_id":"dz09IiwiZXhwIjpudWxsLC",' \
                             '"direct_upload":{"url":"' + upload_url2 + '",' \
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

          stub_request(:post, "http://example.com:3000/v1/resources?accession=#{accession}")
            .with(body: request_dro.to_h.except(:description).to_json, headers: { 'Content-Type' => 'application/json' })
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
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",' \
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",' \
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",' \
                             '"signed_id":"BaHBLZz09Iiw",' \
                             '"direct_upload":{"url":"' + upload_url1 + '",' \
                                                                        '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"dir1/file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",' \
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"dir1-file2.txt",' \
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":36,' \
                             '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",' \
                             '"signed_id":"dz09IiwiZXhwIjpudWxsLC",' \
                             '"direct_upload":{"url":"' + upload_url2 + '",' \
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

          stub_request(:post, "http://example.com:3000/v1/resources?accession=#{accession}")
            .to_return(status: 400, body: '{"id":"bad_request",' \
                                          '"message":"#/components/schemas/DROStructural missing required parameters: isMemberOf"}')
        end

        it 'uploads files' do
          expect { subject }.to raise_error(SdrClient::UnexpectedResponse::BadRequest,
                                            /There was an error with your request/)
        end
      end

      context 'when metadata upload fails with unauthorized' do
        before do
          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",' \
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",' \
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":27,' \
                             '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",' \
                             '"signed_id":"BaHBLZz09Iiw",' \
                             '"direct_upload":{"url":"' + upload_url1 + '",' \
                                                                        '"headers":{"Content-Type":"application/octet-stream"}}}',
                       headers: {})

          stub_request(:post, 'http://example.com:3000/v1/direct_uploads')
            .with(
              body: '{"blob":{"filename":"dir1/file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",' \
                    '"content_type":"application/octet-stream"}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200,
                       body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"dir1-file2.txt",' \
                             '"content_type":"application/octet-stream","metadata":{},"byte_size":36,' \
                             '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",' \
                             '"signed_id":"dz09IiwiZXhwIjpudWxsLC",' \
                             '"direct_upload":{"url":"' + upload_url2 + '",' \
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

          stub_request(:post, "http://example.com:3000/v1/resources?accession=#{accession}")
            .to_return(status: 401)
        end

        it 'uploads files' do
          expect { subject }.to raise_error(SdrClient::UnexpectedResponse::Unauthorized,
                                            /There was an error with your credentials./)
        end
      end
    end
  end
end
