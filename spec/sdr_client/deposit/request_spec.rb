# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::Request do
  context 'with all options set' do
    let(:instance) do
      described_class.new(label: 'This is my object',
                          type: Cocina::Models::ObjectType.book,
                          apo: 'druid:bc123df4567',
                          collection: 'druid:gh123df4567',
                          copyright: 'copyright',
                          source_id: 'googlebooks:12345',
                          catkey: '11991',
                          use_and_reproduction: 'use statement',
                          viewing_direction: 'right-to-left',
                          embargo_release_date: Time.gm(2045),
                          embargo_access: 'stanford',
                          embargo_download: 'stanford',
                          view: 'world',
                          download: 'world')
    end
    let(:with_file_sets) do
      instance.with_file_sets(file_sets)
    end

    let(:file_sets) do
      [
        SdrClient::Deposit::FileSet.new(uploads: [upload1], label: 'Object 1',
                                        uploads_metadata: { 'file1.png' => { view: 'world', download: 'world' } }),
        SdrClient::Deposit::FileSet.new(uploads: [upload2], label: 'Object 2')
      ]
    end

    let(:upload1) do
      SdrClient::Deposit::Files::DirectUploadResponse.new(
        checksum: '',
        byte_size: '',
        filename: 'file1.png',
        content_type: '',
        signed_id: 'foo-file1'
      )
    end

    let(:upload2) do
      SdrClient::Deposit::Files::DirectUploadResponse.new(
        checksum: '',
        byte_size: '',
        filename: 'file2.png',
        content_type: '',
        signed_id: 'bar-file2'
      )
    end

    describe 'as_json' do
      subject { with_file_sets.as_json }

      let(:expected) do
        {
          type: Cocina::Models::ObjectType.book,
          label: 'This is my object',
          version: 1,
          access: {
            view: 'world',
            copyright: 'copyright',
            download: 'world',
            useAndReproductionStatement: 'use statement',
            embargo: {
              releaseDate: '2045-01-01T00:00:00+00:00',
              view: 'stanford',
              download: 'stanford'
            }
          },
          administrative: { hasAdminPolicy: 'druid:bc123df4567' },
          identification: {
            sourceId: 'googlebooks:12345',
            catalogLinks: [{ catalog: 'symphony', catalogRecordId: '11991' }]
          },
          structural: {
            hasMemberOrders: [{ viewingDirection: 'right-to-left' }],
            isMemberOf: ['druid:gh123df4567'],
            contains: [
              {
                type: Cocina::Models::FileSetType.file,
                label: 'Object 1',
                version: 1,
                structural: { contains:
                  [
                    {
                      type: Cocina::Models::ObjectType.file,
                      label: 'file1.png',
                      filename: 'file1.png',
                      access: { view: 'world', download: 'world' },
                      administrative: { publish: true, sdrPreserve: true, shelve: true },
                      externalIdentifier: 'foo-file1',
                      version: 1,
                      hasMessageDigests: []
                    }
                  ] }
              },
              {
                type: Cocina::Models::FileSetType.file,
                label: 'Object 2',
                version: 1,
                structural: { contains:
                  [
                    {
                      type: Cocina::Models::ObjectType.file,
                      label: 'file2.png',
                      filename: 'file2.png',
                      access: { view: 'dark', download: 'none' },
                      administrative: { publish: true, sdrPreserve: true, shelve: false },
                      externalIdentifier: 'bar-file2',
                      version: 1,
                      hasMessageDigests: []
                    }
                  ] }
              }
            ]
          }
        }
      end

      it { is_expected.to eq expected }
    end
  end

  context 'with minimal options set' do
    let(:instance) do
      described_class.new(label: 'This is my object',
                          type: Cocina::Models::ObjectType.object,
                          apo: 'druid:bc123df4567',
                          source_id: 'googlebooks:12345')
    end

    describe 'as_json' do
      subject { instance.as_json }

      let(:expected) do
        {
          type: Cocina::Models::ObjectType.object,
          label: 'This is my object',
          access: {
            view: 'dark',
            download: 'none'
          },
          administrative: { hasAdminPolicy: 'druid:bc123df4567' },
          identification: { sourceId: 'googlebooks:12345' },
          structural: {},
          version: 1
        }
      end

      it { is_expected.to eq expected }
    end
  end
end
