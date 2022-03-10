# frozen_string_literal: true

RSpec.describe SdrClient::Update do
  describe '.run' do
    # rubocop:disable Layout/LineLength
    let(:cocina_json) do
      "{\"type\":\"#{Cocina::Models::ObjectType.document}\",\"externalIdentifier\":\"druid:bw581ng3176\",\"label\":\"Something something better title\",\"version\":1,\"access\":{\"copyright\":\"Some Rights Reserved\",\"useAndReproductionStatement\":\"We are OK with you using this\",\"license\":\"https://www.gnu.org/licenses/agpl.txt\"},\"administrative\":{\"hasAdminPolicy\":\"druid:bc875mg8658\"},\"description\":{\"title\":[{\"value\":\"Something something better title\"}],\"purl\":\"https://purl.example.org/foo\"},\"structural\":{\"isMemberOf\":[\"druid:jh976nm7678\"]}}"
    end
    # rubocop:enable Layout/LineLength

    before do
      allow(SdrClient::Find).to receive(:run).and_return(cocina_json)
      allow(SdrClient::Deposit::UpdateResource).to receive(:run)
    end

    context 'when updating the item APO' do
      let(:new_apo_druid) { 'druid:bj876jg7667' }

      before do
        described_class.run('druid:bc123df4567', apo: new_apo_druid, url: 'http://example.com')
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(administrative: { hasAdminPolicy: new_apo_druid }),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the item collection' do
      let(:new_collection_druid) { 'druid:bk976jg7887' }

      before do
        described_class.run('druid:bc123df4567', collection: new_collection_druid, url: 'http://example.com')
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(structural: { isMemberOf: [new_collection_druid] }),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the item copyright statement' do
      let(:new_copyright) { 'We have changed our minds on copyright after all.' }

      before do
        described_class.run('druid:bc123df4567', copyright: new_copyright, url: 'http://example.com')
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(access: { copyright: new_copyright }),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the item use and reproduction statement' do
      let(:new_use_and_reproduction) { 'Please do not reproduce this.' }

      before do
        described_class.run('druid:bc123df4567', use_and_reproduction: new_use_and_reproduction, url: 'http://example.com')
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(access: { useAndReproductionStatement: new_use_and_reproduction }),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the item license URI' do
      let(:new_license) { 'https://www.apache.org/licenses/LICENSE-2.0' }

      before do
        described_class.run('druid:bc123df4567', license: new_license, url: 'http://example.com')
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(access: { license: new_license }),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end
  end
end
