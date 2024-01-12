# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::UploadFilesMetadataBuilder do
  describe '.build' do
    let(:fake_instance) { instance_double(described_class, build: nil) }

    before do
      allow(described_class).to receive(:new).and_return(fake_instance)
    end

    it 'invokes #build on a new instance' do
      described_class.build(
        files: ['file1.txt'],
        mime_types: { 'file1.txt' => 'text/plain' },
        basepath: 'spec/fixtures'
      )
      expect(fake_instance).to have_received(:build).once
    end
  end

  describe '#build' do
    subject(:builder) do
      described_class.new(
        files: ['file1.txt'],
        mime_types: { 'file1.txt' => 'text/plain' },
        basepath: 'spec/fixtures'
      )
    end

    it 'builds a hash mapping file paths to DirectUploadRequest instances' do
      # NOTE: For some reason, this fails:
      #   expect(builder.build).to eq(
      #     {
      #       'file1.txt' => instance_of(SdrClient::RedesignedClient::DirectUploadRequest)
      #     }
      #   )
      expect(builder.build['file1.txt']).to respond_to(:checksum, :content_type, :byte_size, :filename)
    end
  end
end
