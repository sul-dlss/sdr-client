# frozen_string_literal: true

RSpec.describe SdrClient::Update do
  describe '.run' do
    # rubocop:disable Layout/LineLength
    let(:cocina_json) do
      "{\"type\":\"#{Cocina::Models::ObjectType.document}\",\"externalIdentifier\":\"druid:bw581ng3176\",\"label\":\"Something something better title\",\"version\":1,\"access\":{},\"administrative\":{\"hasAdminPolicy\":\"druid:bc875mg8658\"},\"description\":{\"title\":[{\"value\":\"Something something better title\"}],\"purl\":\"https://purl.example.org/foo\"}}"
    end
    # rubocop:enable Layout/LineLength

    before do
      allow(SdrClient::Find).to receive(:run).and_return(cocina_json)
      allow(SdrClient::Deposit::UpdateResource).to receive(:run)
      described_class.run('druid:bc123df4567', apo: 'druid:bj876jg7667', url: 'http://example.com')
    end

    it 'finds a Cocina object' do
      expect(SdrClient::Find).to have_received(:run).once
    end

    it 'updates a Cocina object' do
      expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once
    end
  end
end
