# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::Request do
  context 'with all options set' do
    let(:instance) do
      described_class.new(label: 'This is my object',
                          type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                          apo: 'druid:bc123df4567',
                          collection: 'druid:gh123df4567',
                          copyright: 'copyright',
                          source_id: 'googlebooks:12345',
                          catkey: '11991',
                          use_statement: 'use statement',
                          viewing_direction: 'right-to-left',
                          embargo_release_date: Time.gm(2045),
                          embargo_access: 'stanford',
                          embargo_download: 'stanford',
                          access: 'world',
                          download: 'world')
    end
    let(:with_file_sets) do
      instance.with_file_sets(file_sets)
    end

    let(:file_sets) do
      [
        SdrClient::Deposit::FileSet.new(uploads: [upload1], label: 'Object 1',
                                        uploads_metadata: { 'file1.png' => { access: 'world', download: 'world' } }),
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
          type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
          label: 'This is my object',
          version: 1,
          access: {
            access: 'world',
            copyright: 'copyright',
            download: 'world',
            useAndReproductionStatement: 'use statement',
            embargo: {
              releaseDate: '2045-01-01T00:00:00+00:00',
              access: 'stanford',
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
                type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                label: 'Object 1',
                version: 1,
                structural: { contains:
                  [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      label: 'file1.png',
                      filename: 'file1.png',
                      access: { access: 'world', download: 'world' },
                      administrative: { publish: true, sdrPreserve: true, shelve: true },
                      externalIdentifier: 'foo-file1',
                      version: 1,
                      hasMessageDigests: []
                    }
                  ] }
              },
              {
                type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                label: 'Object 2',
                version: 1,
                structural: { contains:
                  [
                    {
                      type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                      label: 'file2.png',
                      filename: 'file2.png',
                      access: { access: 'dark', download: 'none' },
                      administrative: { publish: true, sdrPreserve: true, shelve: true },
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
                          type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
                          apo: 'druid:bc123df4567',
                          source_id: 'googlebooks:12345')
    end

    describe 'as_json' do
      subject { instance.as_json }
      let(:expected) do
        {
          type: 'http://cocina.sul.stanford.edu/models/object.jsonld',
          label: 'This is my object',
          access: {
            access: 'dark',
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
