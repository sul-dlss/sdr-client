# frozen_string_literal: true

RSpec.describe SdrClient::Deposit do
  describe 'integration tests' do
    let(:upload_url) { 'http://localhost:3000/v1/disk/GpscGFUTmxO' }

    before do
      stub_request(:post, 'http://example.com/v1/resources?accession=true')
        .to_return(status: 201, body: '{"druid":"druid:bc333df7777"}',
                   headers: { 'Location' => 'http://example.com/background_job/1' })
      stub_request(:post, 'http://example.com/v1/direct_uploads')
        .to_return(
          status: 200,
          body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file four.txt",'\
                '"content_type":"text/html","metadata":{},"byte_size":27,' \
                '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",'\
                '"signed_id":"BaHBLZz09Iiw",'\
                '"direct_upload":{"url":"' + upload_url + '","headers":{"Content-Type":"text/html"}}}',
          headers: {}
        )
      stub_request(:put, 'http://localhost:3000/v1/disk/GpscGFUTmxO')
        .to_return(status: 204, body: '', headers: {})
    end

    it 'passes files metadata through to Process' do
      expect(SdrClient::Deposit::File).to receive(:new).with(
        external_identifier: 'BaHBLZz09Iiw',
        filename: 'file four.txt',
        label: 'file four.txt',
        mime_type: 'text/plain',
        md5: '19531a7fd61429c613d156f53cf3ba76',
        sha1: 'bc59eae52d98e84f83f65fdea3d7857b9ec5c46c',
        use: 'transcription',
        access: 'dark',
        download: 'none'
      ).and_call_original
      described_class.run(apo: 'druid:bc123df4567',
                          collection: 'druid:gh123df4567',
                          source_id: 'googlebooks:12345',
                          url: 'http://example.com/',
                          files: ['spec/fixtures/file four.txt'],
                          files_metadata: {
                            'file four.txt' => {
                              'mime_type' => 'text/plain',
                              'use' => 'transcription'
                            }
                          },
                          accession: true,
                          grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy)
    end
  end

  describe '.run' do
    let(:process) { instance_double(SdrClient::Deposit::Process, run: true) }
    let(:request) { instance_double(SdrClient::Deposit::Request, with_file_sets: second_request) }
    let(:second_request) { instance_double(SdrClient::Deposit::Request, as_json: {}) }

    before do
      allow(SdrClient::Deposit::Request).to receive(:new).and_return(request)
      allow(SdrClient::Deposit::Process).to receive(:new).and_return(process)
    end

    context 'without a grouping_strategy' do
      subject(:run) do
        described_class.run(apo: 'druid:bc123df4567',
                            collection: 'druid:gh123df4567',
                            source_id: 'googlebooks:12345',
                            url: 'http://example.com/')
      end

      it 'runs the process with the default grouping_strategy' do
        run
        expect(SdrClient::Deposit::Process).to have_received(:new)
          .with(grouping_strategy: SdrClient::Deposit::SingleFileGroupingStrategy,
                files: [],
                metadata: request,
                connection: SdrClient::Connection,
                logger: Logger,
                accession: false)

        expect(process).to have_received(:run)
      end
    end

    context 'with a grouping_strategy' do
      subject(:run) do
        described_class.run(apo: 'druid:bc123df4567',
                            collection: 'druid:gh123df4567',
                            source_id: 'googlebooks:12345',
                            url: 'http://example.com/',
                            grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy)
      end

      it 'runs the process with the specified grouping_strategy' do
        run
        expect(SdrClient::Deposit::Process).to have_received(:new)
          .with(grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy,
                files: [],
                metadata: request,
                connection: SdrClient::Connection,
                logger: Logger,
                accession: false)

        expect(process).to have_received(:run)
      end
    end

    context 'with a viewing_direction' do
      subject(:run) do
        described_class.run(apo: 'druid:bc123df4567',
                            collection: 'druid:gh123df4567',
                            source_id: 'googlebooks:12345',
                            url: 'http://example.com/',
                            viewing_direction: 'left-to-right',
                            grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy)
      end

      it 'runs the process with the specified grouping_strategy' do
        run
        expect(SdrClient::Deposit::Request).to have_received(:new)
          .with(
            access: 'dark',
            download: 'none',
            apo: 'druid:bc123df4567',
            catkey: nil,
            collection: 'druid:gh123df4567',
            copyright: nil,
            embargo_access: 'world',
            embargo_download: 'world',
            embargo_release_date: nil,
            files_metadata: {},
            label: nil,
            source_id: 'googlebooks:12345',
            type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
            use_statement: nil,
            viewing_direction: 'left-to-right'
          )

        expect(process).to have_received(:run)
      end
    end

    context 'with copyright and use_statement' do
      subject(:run) do
        described_class.run(apo: 'druid:bc123df4567',
                            collection: 'druid:gh123df4567',
                            copyright: 'All rights reserved unless otherwise indicated.',
                            use_statement: 'Property rights reside with the repository...',
                            source_id: 'googlebooks:12345',
                            url: 'http://example.com/',
                            grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy)
      end

      it 'runs the process with the specified grouping_strategy' do
        run
        expect(SdrClient::Deposit::Request).to have_received(:new)
          .with(
            access: 'dark',
            download: 'none',
            apo: 'druid:bc123df4567',
            catkey: nil,
            collection: 'druid:gh123df4567',
            copyright: 'All rights reserved unless otherwise indicated.',
            embargo_access: 'world',
            embargo_download: 'world',
            embargo_release_date: nil,
            files_metadata: {},
            label: nil,
            source_id: 'googlebooks:12345',
            type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
            use_statement: 'Property rights reside with the repository...',
            viewing_direction: nil
          )

        expect(process).to have_received(:run)
      end
    end
  end
end
