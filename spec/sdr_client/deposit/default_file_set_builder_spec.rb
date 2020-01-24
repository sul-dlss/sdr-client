# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::DefaultFileSetBuilder do
  let(:file_sets) { described_class.run(uploads: uploads) }
  let(:initial_request) do
    SdrClient::Deposit::Request.new(label: 'This is my object',
                                    type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
                                    source_id: 'googlebooks:12345',
                                    collection: 'druid:gh123df4567',
                                    apo: 'druid:bc123df4567')
  end

  let(:uploads) do
    [
      instance_double(SdrClient::Deposit::Files::DirectUploadResponse,
                      filename: '00001.jp2',
                      signed_id: 'xxxxx'),
      instance_double(SdrClient::Deposit::Files::DirectUploadResponse,
                      filename: '00001.html',
                      signed_id: 'xxxxx'),
      instance_double(SdrClient::Deposit::Files::DirectUploadResponse,
                      filename: '00002.jp2',
                      signed_id: 'xxxxx'),
      instance_double(SdrClient::Deposit::Files::DirectUploadResponse,
                      filename: '00002.html',
                      signed_id: 'xxxxx'),
      instance_double(SdrClient::Deposit::Files::DirectUploadResponse,
                      filename: 'stanford_mets.xml',
                      signed_id: 'xxxxx')
    ]
  end

  it 'creates filesets' do
    expect(file_sets.size).to eq 5
  end
end
