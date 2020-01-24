# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::Request do
  let(:instance) do
    described_class.new(label: 'This is my object',
                        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                        apo: 'druid:bc123df4567',
                        collection: 'druid:gh123df4567',
                        source_id: 'googlebooks:12345')
  end
  let(:with_file_sets) do
    instance.with_file_sets(file_set_builder)
  end

  let(:file_set_builder) do
    SdrClient::Deposit::DefaultFileSetBuilder.run(uploads: [upload1, upload2])
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
        access: {},
        administrative: { hasAdminPolicy: 'druid:bc123df4567' },
        identification: { sourceId: 'googlebooks:12345' },
        structural: {
          isMemberOf: 'druid:gh123df4567',
          hasMember: [
            {
              type: 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
              label: 'Object 1',
              structural: { hasMember:
                [
                  {
                    type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                    label: 'file1.png',
                    filename: 'file1.png',
                    access: { access: 'dark' }, administrative: { sdrPreserve: false, shelve: false },
                    externalIdentifier: 'foo-file1'
                  }
                ] }
            },
            {
              type: 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
              label: 'Object 2',
              structural: { hasMember:
                [
                  {
                    type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                    label: 'file2.png',
                    filename: 'file2.png',
                    access: { access: 'dark' }, administrative: { sdrPreserve: false, shelve: false },
                    externalIdentifier: 'bar-file2'
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
