# frozen_string_literal: true

RSpec.describe SdrClient::Credentials do
  describe '.read' do
    subject { described_class.read }

    let(:json) do
      '{"token":"zaa","exp":"2020-04-19"}'
    end

    context 'when the file exists' do
      before do
        described_class.write(json)
      end

      it { is_expected.to eq 'zaa' }
    end

    context "when the file doesn't exist" do
      before do
        allow(described_class).to receive(:credentials_path).and_return('/nonexistant')
      end

      it 'raises' do
        expect { subject }.to raise_error(SdrClient::Credentials::NoCredentialsError)
      end
    end
  end
end
