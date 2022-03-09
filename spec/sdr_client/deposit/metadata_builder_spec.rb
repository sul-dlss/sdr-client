# frozen_string_literal: true

RSpec.describe SdrClient::Deposit::MetadataBuilder do
  subject(:builder) do
    described_class.new(metadata: metadata, grouping_strategy: strategy, logger: logger)
  end

  let(:metadata) { SdrClient::Deposit::Request.new(apo: 'foo', type: type, source_id: 'bar') }
  let(:strategy) do
    class_double(SdrClient::Deposit::MatchingFileGroupingStrategy, run: [[file_upload]])
  end
  let(:logger) { instance_double(Logger) }
  let(:upload_responses) { instance_double(SdrClient::Deposit::UploadFiles) }
  let(:file_upload) do
    instance_double(SdrClient::Deposit::Files::DirectUploadResponse,
                    filename: '0001.jp2',
                    signed_id: '12345')
  end

  describe '#with_uploads' do
    subject(:model) { builder.with_uploads(upload_responses).as_json }

    context 'with an object type' do
      let(:type) { Cocina::Models::ObjectType.object }

      it 'makes attributes for the filesets' do
        file_set = model.dig(:structural, :contains).first
        expect(file_set.fetch(:type)).to eq Cocina::Models::FileSetType.file
        expect(file_set.fetch(:label)).to eq 'Object 1'
      end

      context 'when ImageFileSetStrategy is supplied' do
        subject(:builder) do
          described_class.new(
            metadata: metadata, grouping_strategy: strategy,
            logger: logger, file_set_type_strategy: SdrClient::Deposit::ImageFileSetStrategy
          )
        end

        it 'sets the type to image' do
          file_set = model.dig(:structural, :contains).first
          expect(file_set.fetch(:type)).to eq Cocina::Models::FileSetType.image
        end
      end
    end

    context 'with an book type' do
      let(:type) { SdrClient::Deposit::BOOK_TYPE }

      it 'makes labels for the filesets' do
        file_set = model.dig(:structural, :contains).first
        expect(file_set.fetch(:label)).to eq 'Page 1'
      end
    end
  end
end
