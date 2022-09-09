# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::UpdateDroWithFileIdentifiers do
  subject(:update_dro) do
    described_class.update(request_dro: dro, upload_responses: upload_responses)
  end

  let(:druid) { 'druid:bf024yb8975' }

  let(:dro_hash) do
    {
      cocinaVersion: Cocina::Models::VERSION,
      externalIdentifier: druid,
      type: Cocina::Models::ObjectType.book,
      label: 'Test DRO',
      version: 1,
      description: {
        title: [{ value: 'Test DRO' }],
        purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
      },
      access: { view: 'world', download: 'world' },
      administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
      identification: { sourceId: 'sul:abc123' },
      structural: { contains: [
        {
          type: Cocina::Models::FileSetType.file,
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
          structural: {
            contains: [
              {
                type: Cocina::Models::ObjectType.file,
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                label: '00001.html',
                filename: '00001.html',
                size: 0,
                version: 1,
                hasMimeType: 'text/html',
                use: 'transcription',
                hasMessageDigests: [
                  {
                    type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                  }, {
                    type: 'md5', digest: 'f5eff9e28f154f79f7a11261bc0d4b30'
                  }
                ],
                access: { view: 'dark' },
                administrative: { publish: false, sdrPreserve: true, shelve: false }
              }
            ]
          }
        }
      ] }
    }
  end

  let(:dro) do
    Cocina::Models::DRO.new(dro_hash)
  end

  context 'when file not included in upload responses' do
    let(:upload_responses) do
      [
        SdrClient::Deposit::Files::DirectUploadResponse.new(filename: '00002.html', signed_id: 'abc123')
      ]
    end

    it 'does not update the file' do
      expect(update_dro.structural.contains.first.structural.contains.first.externalIdentifier).to eq('https://cocina.sul.stanford.edu/file/123-456-789')
    end
  end

  context 'when file included in upload responses' do
    let(:upload_responses) do
      [
        SdrClient::Deposit::Files::DirectUploadResponse.new(filename: '00001.html', signed_id: 'abc123')
      ]
    end

    it 'does updates the file' do
      expect(update_dro.structural.contains.first.structural.contains.first.externalIdentifier).to eq('abc123')
    end
  end
end
