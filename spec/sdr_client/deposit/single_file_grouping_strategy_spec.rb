# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::SingleFileGroupingStrategy do
  let(:file_sets) { described_class.run(uploads: uploads) }

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
