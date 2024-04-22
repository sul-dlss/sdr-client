# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::DirectUploadRequest do
  describe '.from_file' do
    it 'sets blank content_type to application/octet-stream' do
      expect(described_class.from_file('spec/fixtures/file1.txt', file_name: 'file1.png', content_type: ''))
        .to have_attributes(
          filename: 'file1.png', content_type: 'application/octet-stream', byte_size: 27,
          checksum: 'hagfaf2F1Cx0r3jnHtIe9Q=='
        )
    end

    it 'sets nil content_type to application/octet-stream' do
      expect(described_class.from_file('spec/fixtures/file1.txt', file_name: 'file1.png', content_type: nil))
        .to have_attributes(
          filename: 'file1.png', content_type: 'application/octet-stream', byte_size: 27,
          checksum: 'hagfaf2F1Cx0r3jnHtIe9Q=='
        )
    end

    it 'sets application/json content_type to application/x-stanford-json' do
      expect(described_class.from_file('spec/fixtures/file1.txt', file_name: 'file1.png',
                                                                  content_type: 'application/json'))
        .to have_attributes(filename: 'file1.png', content_type: 'application/x-stanford-json', byte_size: 27,
                            checksum: 'hagfaf2F1Cx0r3jnHtIe9Q==')
    end

    it 'leaves application/xml content_type alone' do
      expect(described_class.from_file('spec/fixtures/file1.txt', file_name: 'file1.png',
                                                                  content_type: 'application/xml'))
        .to have_attributes(filename: 'file1.png', content_type: 'application/xml', byte_size: 27,
                            checksum: 'hagfaf2F1Cx0r3jnHtIe9Q==')
    end

    it 'removes extra part of content_type after semicolon' do
      expect(described_class.from_file('spec/fixtures/file1.txt', file_name: 'file1.png',
                                                                  content_type: 'application/x-stata-dta;version=14'))
        .to have_attributes(filename: 'file1.png', content_type: 'application/x-stata-dta', byte_size: 27,
                            checksum: 'hagfaf2F1Cx0r3jnHtIe9Q==')
    end
  end

  describe '.to_h' do
    it 'sets blank content_type to application/octet-stream' do
      expect(described_class.new(filename: 'file1.png', checksum: '1234', byte_size: 27, content_type: '').to_h)
        .to eq({ blob: { filename: 'file1.png', byte_size: 27, checksum: '1234',
                         content_type: 'application/octet-stream' } })
    end

    it 'sets nil content_type to application/octet-stream' do
      expect(described_class.new(filename: 'file1.png', checksum: '1234', byte_size: 27, content_type: nil).to_h)
        .to eq({ blob: { filename: 'file1.png', byte_size: 27, checksum: '1234',
                         content_type: 'application/octet-stream' } })
    end

    it 'sets application/json content_type to application/x-stanford-json' do
      expect(described_class.new(filename: 'file1.png', checksum: '1234', byte_size: 27,
                                 content_type: 'application/json').to_h)
        .to eq({ blob: { filename: 'file1.png', byte_size: 27, checksum: '1234',
                         content_type: 'application/x-stanford-json' } })
    end

    it 'leaves application/xml content_type alone' do
      expect(described_class.new(filename: 'file1.png', checksum: '1234', byte_size: 27,
                                 content_type: 'application/xml').to_h)
        .to eq({ blob: { filename: 'file1.png', byte_size: 27, checksum: '1234', content_type: 'application/xml' } })
    end

    it 'removes extra part of content_type after semicolon' do
      expect(described_class.new(filename: 'file1.png', checksum: '1234', byte_size: 27,
                                 content_type: 'application/x-stata-dta;version=14').to_h)
        .to eq({ blob: { filename: 'file1.png', byte_size: 27, checksum: '1234',
                         content_type: 'application/x-stata-dta' } })
    end
  end
end
