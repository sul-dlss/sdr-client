# frozen_string_literal: true

RSpec.describe SdrClient::Update do
  describe '.run' do
    let(:cocina_json) do
      { 'type' => Cocina::Models::ObjectType.document,
        'externalIdentifier' => 'druid:bw581ng3176',
        'label' => 'Something something better title',
        'version' => 1,
        'access' =>
         { 'copyright' => 'Some Rights Reserved',
           'useAndReproductionStatement' => 'We are OK with you using this',
           'license' => 'https://www.gnu.org/licenses/agpl.txt',
           'view' => 'world',
           'download' => 'world' },
        'administrative' => { 'hasAdminPolicy' => 'druid:bc875mg8658' },
        'identification' => {},
        'description' =>
         { 'title' => [{ 'value' => 'Something something better title' }],
           'purl' => 'https://purl.example.org/foo' },
        'structural' =>
         { 'isMemberOf' => ['druid:jh976nm7678'],
           'contains' =>
           [{ 'type' => Cocina::Models::FileSetType.file,
              'externalIdentifier' => 'bw581ng3176_1',
              'label' => 'Test file',
              'version' => 1,
              'structural' =>
              { 'contains' =>
                [{ 'type' => Cocina::Models::ObjectType.file,
                   'externalIdentifier' => 'druid:bw581ng3176/test.txt',
                   'label' => 'test.txt',
                   'filename' => 'test.txt',
                   'size' => 11,
                   'version' => 1,
                   'hasMimeType' => 'text/plain',
                   'hasMessageDigests' =>
                   [{ 'type' => 'sha1',
                      'digest' => '5d39343e4bb48abd97f759828282f5ebbac56c5e' },
                    { 'type' => 'md5', 'digest' => '63b8812b0c05722a9d6c51cbd2bfb54b' }],
                   'access' => { 'view' => 'world', 'download' => 'world' },
                   'administrative' =>
                   { 'sdrPreserve' => true, 'shelve' => true, 'publish' => true } }] } }] } }.to_json
    end

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

    context 'when updating the item access controls (controlled digital lending)' do
      let(:new_view) { 'stanford' }
      let(:new_download) { 'none' }
      let(:new_cdl) { true }

      before do
        described_class.run(
          'druid:bc123df4567',
          view: new_view,
          download: new_download,
          cdl: new_cdl,
          url: 'http://example.com'
        )
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(
            access: {
              view: new_view,
              download: new_download,
              location: nil,
              controlledDigitalLending: true
            },
            structural: {
              contains: [
                {
                  type: Cocina::Models::FileSetType.file,
                  externalIdentifier: 'bw581ng3176_1',
                  label: 'Test file',
                  version: 1,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: 'druid:bw581ng3176/test.txt',
                        label: 'test.txt',
                        filename: 'test.txt',
                        size: 11,
                        version: 1,
                        hasMimeType: 'text/plain',
                        hasMessageDigests: [
                          {
                            type: 'sha1',
                            digest: '5d39343e4bb48abd97f759828282f5ebbac56c5e'
                          },
                          {
                            type: 'md5',
                            digest: '63b8812b0c05722a9d6c51cbd2bfb54b'
                          }
                        ],
                        access: {
                          view: new_view,
                          download: new_download,
                          location: nil,
                          controlledDigitalLending: true
                        },
                        administrative: {
                          sdrPreserve: true,
                          shelve: true,
                          publish: true
                        }
                      }
                    ]
                  }
                }
              ]
            }
          ),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the item access controls (location-based)' do
      let(:new_view) { 'location-based' }
      let(:new_download) { 'location-based' }
      let(:new_location) { 'm&m' }

      before do
        described_class.run(
          'druid:bc123df4567',
          view: new_view,
          download: new_download,
          location: new_location,
          url: 'http://example.com'
        )
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(
            access: {
              view: new_view,
              download: new_download,
              location: new_location
            },
            structural: {
              contains: [
                {
                  type: Cocina::Models::FileSetType.file,
                  externalIdentifier: 'bw581ng3176_1',
                  label: 'Test file',
                  version: 1,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: 'druid:bw581ng3176/test.txt',
                        label: 'test.txt',
                        filename: 'test.txt',
                        size: 11,
                        version: 1,
                        hasMimeType: 'text/plain',
                        hasMessageDigests: [
                          {
                            type: 'sha1',
                            digest: '5d39343e4bb48abd97f759828282f5ebbac56c5e'
                          },
                          {
                            type: 'md5',
                            digest: '63b8812b0c05722a9d6c51cbd2bfb54b'
                          }
                        ],
                        access: {
                          view: new_view,
                          download: new_download,
                          location: new_location,
                          controlledDigitalLending: false
                        },
                        administrative: {
                          sdrPreserve: true,
                          shelve: true,
                          publish: true
                        }
                      }
                    ]
                  }
                }
              ]
            }
          ),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the item access controls (dark)' do
      let(:new_view) { 'dark' }
      let(:new_download) { 'none' }

      before do
        described_class.run(
          'druid:bc123df4567',
          view: new_view,
          download: new_download,
          url: 'http://example.com'
        )
      end

      it 'finds a Cocina object' do
        expect(SdrClient::Find).to have_received(:run).once
      end

      it 'updates a Cocina object' do
        expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
          metadata: cocina_object_with(
            access: {
              view: new_view,
              download: new_download
            },
            structural: {
              contains: [
                {
                  type: Cocina::Models::FileSetType.file,
                  externalIdentifier: 'bw581ng3176_1',
                  label: 'Test file',
                  version: 1,
                  structural: {
                    contains: [
                      {
                        type: Cocina::Models::ObjectType.file,
                        externalIdentifier: 'druid:bw581ng3176/test.txt',
                        label: 'test.txt',
                        filename: 'test.txt',
                        size: 11,
                        version: 1,
                        hasMimeType: 'text/plain',
                        hasMessageDigests: [
                          {
                            type: 'sha1',
                            digest: '5d39343e4bb48abd97f759828282f5ebbac56c5e'
                          },
                          {
                            type: 'md5',
                            digest: '63b8812b0c05722a9d6c51cbd2bfb54b'
                          }
                        ],
                        access: {
                          view: new_view,
                          download: new_download,
                          location: nil,
                          controlledDigitalLending: false
                        },
                        administrative: {
                          sdrPreserve: true,
                          shelve: false,
                          publish: false
                        }
                      }
                    ]
                  }
                }
              ]
            }
          ),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end
  end
end
