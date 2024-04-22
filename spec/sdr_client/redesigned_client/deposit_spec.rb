# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::Deposit do
  subject(:deposit) do
    described_class.deposit_model(files: files, model: model, basepath: basepath, accession: true, **options)
  end

  let(:basepath) { 'spec/fixtures' }
  let(:file_name) { 'file1.txt' }
  let(:files) { [file_name] }
  let(:model) { build(:request_dro).new(**attributes) }
  let(:options) { { priority: 'low', assign_doi: true } }
  let(:url) { 'https://sdr-api.example.edu' }

  before do
    SdrClient::RedesignedClient.configure(
      email: 'testing@example.edu',
      password: 'password',
      url: url
    )
  end

  describe '.deposit_model' do
    let(:attributes) do
      {
        structural: {
          contains: [
            {
              type: Cocina::Models::FileSetType.file,
              label: 'Page 1',
              version: 1,
              structural: {
                contains: [
                  {
                    type: Cocina::Models::ObjectType.file,
                    label: file_name,
                    filename: file_name,
                    access: { 'view' => 'dark', 'download' => 'none' },
                    administrative: { 'publish' => false, 'sdrPreserve' => false, 'shelve' => false },
                    version: 1,
                    hasMessageDigests: []
                  }
                ]
              }
            }
          ]
        }
      }
    end

    before do
      allow(SdrClient::RedesignedClient.config.logger).to receive(:info)
      allow(SdrClient::RedesignedClient::UploadFilesMetadataBuilder).to receive(:build)
      allow(SdrClient::RedesignedClient::UploadFiles).to receive(:upload)
      allow(SdrClient::RedesignedClient::StructuralGrouper).to receive(:group)
      allow(SdrClient::RedesignedClient::UpdateDroWithFileIdentifiers).to receive(:update)
      allow(SdrClient::RedesignedClient::CreateResource).to receive(:run)
    end

    it 'logs a message about checking that files exist' do
      deposit
      expect(SdrClient::RedesignedClient.config.logger)
        .to have_received(:info).with('checking to see if files exist').once
    end

    context 'with no structural metadata' do
      let(:files) { [] }
      # NOTE: in the absence of cocina-models factories providing an easier way
      #       to build a model *without* certain attrs...
      let(:model) do
        Cocina::Models.build_request(
          build(:request_dro)
            .to_h
            .except(:structural)
        )
      end

      it 'does not raise' do
        expect { deposit }.not_to raise_error
      end
    end

    context 'when files are missing from the filesystem' do
      let(:file_name) { 'file99.txt' }

      it 'raises Errno::ENOENT' do
        expect { deposit }.to raise_error(Errno::ENOENT)
        expect(SdrClient::RedesignedClient::UploadFilesMetadataBuilder).not_to have_received(:build)
        expect(SdrClient::RedesignedClient::UploadFiles).not_to have_received(:upload)
        expect(SdrClient::RedesignedClient::StructuralGrouper).not_to have_received(:group)
        expect(SdrClient::RedesignedClient::UpdateDroWithFileIdentifiers).not_to have_received(:update)
        expect(SdrClient::RedesignedClient::CreateResource).not_to have_received(:run)
      end
    end

    context 'when passed a file path that does not appear in structural metadata' do
      let(:files) { [file_name, 'file3.txt'] }

      it 'raises RuntimeError' do
        expect { deposit }.to raise_error(RuntimeError, /Request file not provided for/)
        expect(SdrClient::RedesignedClient::UploadFilesMetadataBuilder).not_to have_received(:build)
        expect(SdrClient::RedesignedClient::UploadFiles).not_to have_received(:upload)
        expect(SdrClient::RedesignedClient::StructuralGrouper).not_to have_received(:group)
        expect(SdrClient::RedesignedClient::UpdateDroWithFileIdentifiers).not_to have_received(:update)
        expect(SdrClient::RedesignedClient::CreateResource).not_to have_received(:run)
      end
    end

    context 'when passed structural metadata that references file paths that were not provided' do
      let(:attributes) do
        {
          structural: {
            contains: [
              {
                type: Cocina::Models::FileSetType.file,
                label: 'Page 1',
                version: 1,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      label: file_name,
                      filename: file_name,
                      access: { 'view' => 'dark', 'download' => 'none' },
                      administrative: { 'publish' => false, 'sdrPreserve' => false, 'shelve' => false },
                      version: 1,
                      hasMessageDigests: []
                    }
                  ]
                }
              },
              {
                type: Cocina::Models::FileSetType.file,
                label: 'Page 1',
                version: 1,
                structural: {
                  contains: [
                    {
                      type: Cocina::Models::ObjectType.file,
                      label: 'file3.txt',
                      filename: 'file3.txt',
                      access: { 'view' => 'dark', 'download' => 'none' },
                      administrative: { 'publish' => false, 'sdrPreserve' => false, 'shelve' => false },
                      version: 1,
                      hasMessageDigests: []
                    }
                  ]
                }
              }
            ]
          }
        }
      end

      it 'raises RuntimeError' do
        expect { deposit }.to raise_error(RuntimeError, /File not provided for request file/)
        expect(SdrClient::RedesignedClient::UploadFilesMetadataBuilder).not_to have_received(:build)
        expect(SdrClient::RedesignedClient::UploadFiles).not_to have_received(:upload)
        expect(SdrClient::RedesignedClient::StructuralGrouper).not_to have_received(:group)
        expect(SdrClient::RedesignedClient::UpdateDroWithFileIdentifiers).not_to have_received(:update)
        expect(SdrClient::RedesignedClient::CreateResource).not_to have_received(:run)
      end
    end

    it 'uses UploadFilesMetadataBuilder to build file metadata' do
      deposit
      expect(SdrClient::RedesignedClient::UploadFilesMetadataBuilder).to have_received(:build).once
    end

    it 'uses UploadFiles to build upload responses' do
      deposit
      expect(SdrClient::RedesignedClient::UploadFiles).to have_received(:upload).once
    end

    context 'when passed the `request_builder` option' do
      let(:fake_builder) { instance_double(SdrClient::RedesignedClient::RequestBuilder, for: {}) }
      let(:options) do
        {
          request_builder: fake_builder
        }
      end

      before do
        allow(SdrClient::RedesignedClient::RequestBuilder).to receive(:new).and_return(fake_builder)
        allow(SdrClient::RedesignedClient::StructuralGrouper).to receive(:group).and_return(model)
      end

      it 'uses StructuralGrouper to update model structural metadata per grouping strategies' do
        deposit
        expect(SdrClient::RedesignedClient::StructuralGrouper).to have_received(:group).once
      end
    end

    it 'uses UpdateDroWithFileIdentifiers to rebuild the request model with file IDs' do
      deposit
      expect(SdrClient::RedesignedClient::UpdateDroWithFileIdentifiers).to have_received(:update).once
    end

    it 'uses CreateResource to deposit the request model' do
      deposit
      expect(SdrClient::RedesignedClient::CreateResource).to have_received(:run).once
    end
  end
end
