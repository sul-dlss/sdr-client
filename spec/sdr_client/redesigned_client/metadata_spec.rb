# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::Metadata do
  before do
    SdrClient::RedesignedClient.configure(
      email: 'testing@example.edu',
      password: 'password',
      url: 'http://example.com/'
    )
  end

  describe 'end-to-end test' do
    subject(:metadata_depositor) do
      described_class.new(
        apo: 'druid:bc123df4567',
        basepath: basepath,
        source_id: 'googlebooks:12345',
        collection: 'druid:gh123df4567',
        files: ['file four.txt'],
        files_metadata: {
          'file four.txt' => {
            'mime_type' => 'text/plain',
            'use' => 'transcription'
          }
        },
        accession: true,
        priority: 'low',
        grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy
      )
    end

    let(:upload_url) { 'http://localhost:3000/v1/disk/GpscGFUTmxO' }
    let(:basepath) { 'spec/fixtures' }

    before do
      stub_request(:post, 'http://example.com/v1/direct_uploads')
        .to_return(
          status: 200,
          body: '{"id":37,"key":"gugv9ii3e79k933cjv36x732497s","filename":"file four.txt",' \
                '"content_type":"text/html","metadata":{},"byte_size":27,' \
                '"checksum":"hagfaf2F1Cx0r3jnHtIe9Q==","created_at":"2019-11-16T21:36:03.122Z",' \
                '"signed_id":"BaHBLZz09Iiw",' \
                "\"direct_upload\":{\"url\":\"#{upload_url}\",\"headers\":{\"Content-Type\":\"text/html\"}}}"
        )
      stub_request(:put, 'http://localhost:3000/v1/disk/GpscGFUTmxO')
        .to_return(status: 204, body: '', headers: {})
      stub_request(:post, 'http://example.com/v1/resources?accession=true&priority=low')
        .to_return(status: 201, body: '{"jobId":"1234"}',
                   headers: { 'Location' => 'http://example.com/background_job/1' })
      allow(SdrClient::RedesignedClient::File).to receive(:new).and_call_original
    end

    it 'navigates through requests to return a job ID' do
      expect(metadata_depositor.deposit).to eq('1234')
    end

    it 'passes through expected file attributes' do
      metadata_depositor.deposit
      expect(SdrClient::RedesignedClient::File).to have_received(:new)
        .with(external_identifier: 'BaHBLZz09Iiw', filename: 'file four.txt', label: 'file four.txt', view: 'dark',
              mime_type: 'text/plain', md5: '19531a7fd61429c613d156f53cf3ba76',
              sha1: 'bc59eae52d98e84f83f65fdea3d7857b9ec5c46c', use: 'transcription', download: 'none').once
    end
  end
end
