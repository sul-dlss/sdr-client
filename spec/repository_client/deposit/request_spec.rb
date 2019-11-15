# frozen_string_literal: true

RSpec.describe RepositoryClient::Deposit::Request do
  let(:instance) do
    described_class.new(label: 'This is my object',
                        type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                        uploads: [upload1, upload2])
  end

  let(:upload1) do
    RepositoryClient::Deposit::Files::DirectUploadResponse.new(
      checksum: '',
      byte_size: '',
      file_name: 'file1.png',
      content_type: '',
      signed_id: 'foo-file1'
    )
  end

  let(:upload2) do
    RepositoryClient::Deposit::Files::DirectUploadResponse.new(
      checksum: '',
      byte_size: '',
      file_name: 'file2.png',
      content_type: '',
      signed_id: 'bar-file2'
    )
  end

  describe 'as_json' do
    subject { instance.as_json }
    let(:expected) do
      {
        :@context => 'http://cocina.sul.stanford.edu/contexts/cocina-base.jsonld',
        :@type => 'http://cocina.sul.stanford.edu/models/book.jsonld',
        label: 'This is my object',
        structural: {
          hasMember: [
            {
              :@context => 'http://cocina.sul.stanford.edu/contexts/cocina-base.jsonld',
              :@type => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
              :label => 'file1.png',
              :structural => { hasMember: ['foo-file1'] }
            },
            {
              :@context => 'http://cocina.sul.stanford.edu/contexts/cocina-base.jsonld',
              :@type => 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
              :label => 'file2.png',
              :structural => { hasMember: ['bar-file2'] }
            }
          ]
        }
      }
    end

    it { is_expected.to eq expected }
  end
end
