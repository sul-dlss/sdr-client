# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::Process do
  let(:instance) do
    described_class.new(label: 'This is my object',
                        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                        url: 'http://example.com:3000',
                        files: files,
                        logger: logger)
  end

  let(:logger) { instance_double(Logger, info: nil) }

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
      let(:upload_url1) { 'http://localhost:3000/rails/active_storage/disk/GpscGFUTmxO' }
      let(:upload_url2) { 'http://localhost:3000/rails/active_storage/disk/npoa1pIVjZP' }
      before do
        stub_request(:post, 'http://example.com:3000/rails/active_storage/direct_uploads')
          .with(
            body: '{"blob":{"filename":"file1.txt","byte_size":27,"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==",'\
                  '"content_type":"text/html"}}',
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200,
                     body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file1.txt",'\
                           '"content_type":"text/html","metadata":{},"byte_size":27,' \
                           '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",'\
                           '"signed_id":"BaHBLZz09Iiw",'\
                           '"direct_upload":{"url":"' + upload_url1 + '","headers":{"Content-Type":"text/html"}}}',
                     headers: {})

        stub_request(:post, 'http://example.com:3000/rails/active_storage/direct_uploads')
          .with(
            body: '{"blob":{"filename":"file2.txt","byte_size":36,"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==",'\
                  '"content_type":"text/html"}}',
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(status: 200,
                     body: '{"id":38,"key":"08y78dduz8w077l3lbcrrd5vjk4x","filename":"file2.txt",'\
                           '"content_type":"text/html","metadata":{},"byte_size":36,'\
                           '"checksum":"LzYE2VS+iI3+Wx65v2MJ5A==","created_at":"2019-11-16T21:37:16.657Z",'\
                           '"signed_id":"dz09IiwiZXhwIjpudWxsLC",'\
                           '"direct_upload":{"url":"' + upload_url2 + '","headers":{"Content-Type":"text/html"}}}',
                     headers: {})

        stub_request(:put, upload_url1)
          .with(
            body: "This is a fixture file ...\n",
            headers: {
              'Content-Length' => '27',
              'Content-Type' => 'text/html'
            }
          )
          .to_return(status: 204)

        stub_request(:put, upload_url2)
          .with(
            body: "This is a fixture file for testing.\n",
            headers: {
              'Content-Length' => '36',
              'Content-Type' => 'text/html'
            }
          )
          .to_return(status: 204)
      end

      context 'when metadata upload succeedes' do
        before do
          stub_request(:post, 'http://example.com:3000/v1/resources')
            .with(
              body: '{"@context":"http://cocina.sul.stanford.edu/contexts/cocina-base.jsonld",' \
                    '"@type":"http://cocina.sul.stanford.edu/models/book.jsonld",' \
                    '"label":"This is my object",' \
                    '"structural":{"hasMember":[' \
                    '{"@context":"http://cocina.sul.stanford.edu/contexts/cocina-base.jsonld",' \
                    '"@type":"http://cocina.sul.stanford.edu/models/fileset.jsonld","label":"file1.txt",' \
                    '"structural":{"hasMember":["BaHBLZz09Iiw"]}},'\
                    '{"@context":"http://cocina.sul.stanford.edu/contexts/cocina-base.jsonld",' \
                    '"@type":"http://cocina.sul.stanford.edu/models/fileset.jsonld","label":"file2.txt",' \
                    '"structural":{"hasMember":["dz09IiwiZXhwIjpudWxsLC"]}}' \
                    ']}}',
              headers: { 'Content-Type' => 'application/json' }
            )
            .to_return(status: 200, body: '{"status":"accepted"}')
        end

        it 'uploads files' do
          subject
        end
      end

      context 'when metadata upload fails' do
        before do
          stub_request(:post, 'http://example.com:3000/v1/resources')
            .to_return(status: 400, body: '{"id":"bad_request",' \
              '"message":"#/components/schemas/DROStructural missing required parameters: isMemberOf"}')
        end

        it 'uploads files' do
          expect { subject }.to raise_error(SystemExit)
            .and output("\nThere was an error with your request: " \
              '{"id":"bad_request","message":"#/components/schemas/DROStructural ' \
              "missing required parameters: isMemberOf\"}\n").to_stdout
        end
      end
    end
  end
end
