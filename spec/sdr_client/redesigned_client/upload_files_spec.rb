# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::UploadFiles do
  describe '.upload' do
    let(:fake_instance) { instance_double(described_class, upload: nil) }

    before do
      allow(described_class).to receive(:new).and_return(fake_instance)
    end

    it 'invokes #upload on a new instance' do
      described_class.upload(
        file_metadata: {},
        filepath_map: {}
      )
      expect(fake_instance).to have_received(:upload).once
    end
  end

  describe '#upload' do
    subject(:uploader) do
      described_class.new(file_metadata: file_metadata, filepath_map: filepath_map)
    end

    let(:fake_post_response) do
      {
        filename: 'file1.txt',
        content_type: 'text/plain',
        byte_size: '27',
        checksum: 'hagfaf2F1Cx0r3jnHtIe9Q==',
        signed_id: 'BaHBLZz09Iiw',
        direct_upload: { 'url' => 'https://sdr-api.example.edu/v1/disk/BaHBLZz09Iiw' }
      }
    end
    let(:file_metadata) do
      {
        'file1.txt' => SdrClient::RedesignedClient::DirectUploadRequest.new
      }
    end
    let(:filepath_map) do
      {
        'file1.txt' => File.expand_path('spec/fixtures/file1.txt')
      }
    end

    before do
      SdrClient::RedesignedClient.configure(
        email: 'testing@example.edu',
        password: 'password',
        url: 'https://sdr-api.example.edu'
      )
      allow(SdrClient::RedesignedClient.instance).to receive_messages(
        post: fake_post_response,
        put: {}
      )
    end

    it 'returns a list of upload responses' do
      expect(uploader.upload.count).to eq(filepath_map.count)
      expect(uploader.upload.first).to be_a(SdrClient::RedesignedClient::DirectUploadResponse)
      expect(uploader.upload.first.filename).to eq('file1.txt')
    end

    it 'POSTs provided metadata to the uploads endpoint' do
      uploader.upload
      expect(SdrClient::RedesignedClient.instance).to have_received(:post).once
    end

    it 'PUTs the provided files to the uploads endpoint' do
      uploader.upload
      expect(SdrClient::RedesignedClient.instance).to have_received(:put).once
    end
  end
end
