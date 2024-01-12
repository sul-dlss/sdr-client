# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::StructuralGrouper do
  subject(:grouper) do
    described_class.new(
      request_builder: request_builder,
      upload_responses: fake_upload_responses,
      grouping_strategy: grouping_strategy,
      **file_set_strategy_arg
    )
  end

  let(:request_builder) { instance_double(SdrClient::RedesignedClient::RequestBuilder) }
  let(:fake_upload_responses) do
    [
      SdrClient::RedesignedClient::DirectUploadResponse.new(filename: 'file1.txt', signed_id: 'abc123'),
      SdrClient::RedesignedClient::DirectUploadResponse.new(filename: 'file1.csv', signed_id: 'zyx987')
    ]
  end
  let(:file_set_strategy_arg) { {} }
  let(:grouping_strategy) { 'single' }

  describe '.group' do
    let(:fake_grouper) { instance_double(described_class, group: nil) }

    before do
      allow(described_class).to receive(:new).and_return(fake_grouper)
    end

    it 'invokes #group on a new instance' do
      described_class.group(request_builder: request_builder,
                            upload_responses: [],
                            grouping_strategy: 'single')
      expect(fake_grouper).to have_received(:group).once
    end
  end

  describe '#initialize' do
    context 'when grouping_strategy param is "filename"' do
      let(:grouping_strategy) { 'filename' }

      it 'uses the matching file grouping strategy' do
        expect(grouper.send(:grouping_strategy)).to eq(SdrClient::RedesignedClient::MatchingFileGroupingStrategy)
      end
    end

    context 'when grouping_strategy param is any value other than "filename"' do
      it 'defaults to the single file grouping strategy' do
        expect(grouper.send(:grouping_strategy)).to eq(SdrClient::RedesignedClient::SingleFileGroupingStrategy)
      end
    end

    context 'when file_set_type_strategy param is "image"' do
      let(:file_set_strategy_arg) { { file_set_strategy: 'image' } }

      it 'uses the image file set strategy' do
        expect(grouper.send(:file_set_strategy)).to eq(SdrClient::RedesignedClient::ImageFileSetStrategy)
      end
    end

    context 'when file_set_type_strategy param is any value other than "image"' do
      it 'defaults to the file type file set strategy' do
        expect(grouper.send(:file_set_strategy)).to eq(SdrClient::RedesignedClient::FileTypeFileSetStrategy)
      end
    end
  end

  describe '#group' do
    subject(:file_sets) { grouper.group.structural.contains }

    let(:request_builder) do
      SdrClient::RedesignedClient::RequestBuilder.new(
        apo: 'druid:bc123df4567',
        source_id: 'sul:123',
        **request_builder_options
      )
    end
    let(:request_builder_options) do
      {
        files_metadata: {
          'file1.txt' => {
            view: 'stanford',
            download: 'stanford',
            preserve: false,
            shelve: true,
            publish: false
          }
        },
        view: 'world',
        download: 'world'
      }
    end

    context 'with defaults (single file grouping strategy) & file-type file set strategy' do
      it 'groups files into two file sets' do
        expect(file_sets.count).to eq(2)
      end

      it 'sets the file set type as expected' do
        expect(file_sets.map(&:type).uniq).to eq([Cocina::Models::FileSetType.file])
      end

      it 'uses the file-oriented file set label' do
        expect(file_sets.map(&:label)).to all(start_with('Object '))
      end
    end

    context 'with the matching file grouping strategy' do
      let(:grouping_strategy) { 'filename' }

      it 'groups files into a file set with both files' do
        expect(file_sets.first.structural.contains.count).to eq(2)
      end
    end

    context 'with the image file set strategy' do
      let(:file_set_strategy_arg) { { file_set_strategy: 'image' } }

      it 'sets the file set type as expected' do
        expect(file_sets.map(&:type).uniq).to eq([Cocina::Models::FileSetType.image])
      end
    end

    context 'with a book-type object' do
      let(:request_builder_options) { { type: Cocina::Models::ObjectType.book } }

      it 'uses the book-oriented file set label' do
        expect(file_sets.map(&:label)).to all(start_with('Page '))
      end
    end
  end
end
