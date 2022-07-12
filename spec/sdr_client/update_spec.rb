# frozen_string_literal: true

RSpec.describe SdrClient::Update do
  describe '.run' do
    let(:structural) do
      {
        isMemberOf: ['druid:jh976nm7678'],
        contains: [
          {
            type: Cocina::Models::FileSetType.file,
            externalIdentifier: 'bw581ng3176_1',
            label: 'Test file',
            version: 1,
            structural:
            {
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
                    { type: 'sha1', digest: '5d39343e4bb48abd97f759828282f5ebbac56c5e' },
                    { type: 'md5', digest: '63b8812b0c05722a9d6c51cbd2bfb54b' }
                  ],
                  access: { view: 'world', download: 'world' },
                  administrative: { sdrPreserve: true, shelve: true, publish: true }
                }
              ]
            }
          }
        ]
      }
    end

    let(:access) do
      {
        copyright: 'Some Rights Reserved',
        useAndReproductionStatement: 'We are OK with you using this',
        license: 'https://www.gnu.org/licenses/agpl.txt',
        view: 'world',
        download: 'world'
      }
    end

    let(:dro) do
      build(
        :dro,
        type: Cocina::Models::ObjectType.document, id: 'druid:bw581ng3176', label: 'Something something better title',
        admin_policy_id: 'druid:bc875mg8658', source_id: 'sul:123'
      ).new(
        access: access, structural: structural
      )
    end

    let(:cocina_json) { dro.to_h.to_json }

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
      let(:updated_structural) do
        structural.dup.tap do |h|
          h[:contains][0][:structural][:contains][0][:access] =
            {
              view: new_view,
              download: new_download,
              location: nil,
              controlledDigitalLending: true
            }
        end
      end

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
            structural: updated_structural
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
      let(:updated_structural) do
        structural.dup.tap do |h|
          h[:contains][0][:structural][:contains][0][:access] =
            {
              view: new_view,
              download: new_download,
              location: new_location,
              controlledDigitalLending: false
            }
        end
      end

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
            structural: updated_structural
          ),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the item access controls (dark)' do
      let(:new_view) { 'dark' }
      let(:new_download) { 'none' }
      let(:updated_structural) do
        structural.dup.tap do |h|
          file_info = h[:contains][0][:structural][:contains][0]
          file_info[:access] =
            {
              view: new_view,
              download: new_download,
              location: nil,
              controlledDigitalLending: false
            }
          file_info[:administrative] =
            {
              sdrPreserve: true,
              shelve: false,
              publish: false
            }
        end
      end

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
            structural: updated_structural
          ),
          logger: instance_of(Logger),
          connection: instance_of(SdrClient::Connection)
        )
      end
    end

    context 'when updating the full cocina via file' do
      let(:cocina_file) { 'bw581ng3176.json' }
      let(:new_cocina) do
        build(
          :dro,
          id: 'druid:bw581ng3176', label: 'An EVEN better title', admin_policy_id: 'druid:bc875mg8658', source_id: 'sul:123'
        ).new(
          access: {
            copyright: 'More Rights Reserved',
            useAndReproductionStatement: 'We are OK with you using this',
            license: 'https://www.gnu.org/licenses/agpl.txt',
            view: 'world',
            download: 'world'
          }
        )
      end
      let(:file_check) { true }
      let(:readable_check) { true }

      before do
        allow(File).to receive(:file?).and_return(file_check)
        allow(File).to receive(:readable?).and_return(readable_check)
        allow(File).to receive(:read).and_return(new_cocina.to_json)
      end

      context 'when happy path' do
        before do
          described_class.run('druid:bw581ng3176', cocina_file: cocina_file, url: 'http://example.com')
        end

        it 'finds a Cocina object' do
          expect(SdrClient::Find).to have_received(:run).once
        end

        it 'updates a Cocina object' do
          expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
            metadata: cocina_object_with(**new_cocina),
            logger: instance_of(Logger),
            connection: instance_of(SdrClient::Connection)
          )
        end
      end

      context 'when given cocina file that is not a file' do
        let(:file_check) { false }
        let(:readable_check) { true }

        it 'raises a runtime error' do
          expect { described_class.run('druid:bw581ng3176', cocina_file: cocina_file, url: 'http://example.com') }.to raise_error(
            RuntimeError,
            /File not found: #{cocina_file}/
          )
        end
      end

      context 'when given cocina file that is not readable' do
        let(:file_check) { true }
        let(:readable_check) { false }

        it 'raises a runtime error' do
          expect { described_class.run('druid:bw581ng3176', cocina_file: cocina_file, url: 'http://example.com') }.to raise_error(
            RuntimeError,
            /File not found: #{cocina_file}/
          )
        end
      end

      context 'when given cocina file with a non-matching external identifier' do
        let(:new_cocina) do
          build(
            :dro,
            id: 'druid:bw581ng3179', # this is different from above
            label: 'An EVEN better title', admin_policy_id: 'druid:bc875mg8658'
          ).new(
            access: {
              copyright: 'More Rights Reserved',
              useAndReproductionStatement: 'We are OK with you using this',
              license: 'https://www.gnu.org/licenses/agpl.txt',
              view: 'world',
              download: 'world'
            }
          )
        end

        it 'raises a runtime error' do
          expect { described_class.run('druid:bw581ng3176', cocina_file: cocina_file, url: 'http://example.com') }.to raise_error(
            RuntimeError,
            /Cocina in #{cocina_file} has a different external identifier/
          )
        end
      end
    end

    context 'when updating the full cocina via pipe' do
      let(:new_cocina) do
        build(
          :dro,
          id: 'druid:bw581ng3176', label: 'An EVEN better title', admin_policy_id: 'druid:bc875mg8658', source_id: 'sul:123'
        ).new(
          access: {
            copyright: 'More Rights Reserved',
            useAndReproductionStatement: 'We are OK with you using this',
            license: 'https://www.gnu.org/licenses/agpl.txt',
            view: 'world',
            download: 'world'
          }
        )
      end
      let(:stdin_check) { true }

      before do
        allow($stdin).to receive(:stat).and_return(instance_double(File::Stat, pipe?: stdin_check))
        allow($stdin).to receive(:read).and_return(new_cocina.to_json)
      end

      context 'when happy path' do
        before do
          described_class.run('druid:bw581ng3176', cocina_pipe: true, url: 'http://example.com')
        end

        it 'finds a Cocina object' do
          expect(SdrClient::Find).to have_received(:run).once
        end

        it 'updates a Cocina object' do
          expect(SdrClient::Deposit::UpdateResource).to have_received(:run).once.with(
            metadata: cocina_object_with(**new_cocina),
            logger: instance_of(Logger),
            connection: instance_of(SdrClient::Connection)
          )
        end
      end

      context 'when given cocina pipe without stdin' do
        let(:stdin_check) { false }

        it 'raises a runtime error' do
          expect { described_class.run('druid:bw581ng3176', cocina_pipe: true, url: 'http://example.com') }.to raise_error(
            RuntimeError,
            /No pipe provided/
          )
        end
      end

      context 'when given piped cocina with a non-matching external identifier' do
        let(:new_cocina) do
          build(
            :dro,
            id: 'druid:bw581ng3179', # this is different from above
            label: 'An EVEN better title', admin_policy_id: 'druid:bc875mg8658'
          ).new(
            access: {
              copyright: 'More Rights Reserved',
              useAndReproductionStatement: 'We are OK with you using this',
              license: 'https://www.gnu.org/licenses/agpl.txt',
              view: 'world',
              download: 'world'
            }
          )
        end

        it 'raises a runtime error' do
          expect { described_class.run('druid:bw581ng3176', cocina_pipe: true, url: 'http://example.com') }.to raise_error(
            RuntimeError,
            /Cocina piped in has a different external identifier/
          )
        end
      end
    end
  end
end
