# frozen_string_literal: true

RSpec.describe SdrClient::RedesignedClient::Find do
  before do
    SdrClient::RedesignedClient.configure(
      email: 'testing@example.edu',
      password: 'password',
      url: 'http://example.com/'
    )
  end

  describe 'run' do
    subject(:find) { described_class.run(object_id: 'druid:bw581ng3176') }

    context 'when happy path' do
      before do
        stub_request(:get, 'http://example.com/v1/resources/druid:bw581ng3176')
          .to_return(status: 200, body: json, headers: {})
        allow(SdrClient::RedesignedClient.config.logger).to receive(:info)
      end

      let(:json) do
        <<~JSON
          {"type":"#{Cocina::Models::ObjectType.document}","externalIdentifier":"druid:bw581ng3176","label":"Something something better title","version":1,"access":{"access":"stanford","copyright":"This work is copyrighted by the creator.","download":"stanford","useAndReproductionStatement":"This document is available only to the Stanford faculty, staff and student community."},"administrative":{"hasAdminPolicy":"druid:zx485kb6348"},"description":{"title":[{"value":"Something something better title"}],"contributor":[{"name":[{"value":"Hodge, Amy"}],"type":"person","role":[{"value":"Author"},{"value":"author","uri":"http://id.loc.gov/vocabulary/relators/aut","source":{"code":"marcrelator","uri":"http://id.loc.gov/vocabulary/relators/"}},{"value":"Creator"}]}],"form":[{"structuredValue":[{"value":"Text","type":"type"},{"value":"Report","type":"subtype"}],"type":"resource type","source":{"value":"Stanford self-deposit resource types"}},{"value":"reports","type":"genre","uri":"http://vocab.getty.edu/aat/300027267","source":{"code":"aat"}},{"value":"text","type":"resource type","source":{"value":"MODS resource types"}}],"note":[{"value":";alkdfjlsadkjf;l","type":"summary"},{"value":"amyhodge@stanford.edu","type":"contact","displayLabel":"Contact"}],"subject":[{"value":"lkfj","type":"topic"},{"value":";kfj","type":"topic"},{"value":"fjwelkb","type":"topic"}]},"identification":{"sourceId":"hydrus:20"},"structural":{"contains":[{"type":"sul.stanford.edu/models/resources/file.jsonld","externalIdentifier":"bw581ng3176_1","label":"Test file","version":1,"structural":{"contains":[{"type":"#{Cocina::Models::ObjectType.file}","externalIdentifier":"druid:bw581ng3176/test.txt","label":"test.txt","filename":"test.txt","size":11,"version":1,"hasMimeType":"text/plain","hasMessageDigests":[{"type":"sha1","digest":"5d39343e4bb48abd97f759828282f5ebbac56c5e"},{"type":"md5","digest":"63b8812b0c05722a9d6c51cbd2bfb54b"}],"access":{"access":"world","download":"world"},"administrative":{"sdrPreserve":true,"shelve":true}}]}}]}}
        JSON
      end

      it 'includes the druid' do
        expect(find[:externalIdentifier]).to eq('druid:bw581ng3176')
      end

      it 'logs the operation' do
        find
        expect(SdrClient::RedesignedClient.config.logger).to have_received(:info).once
      end
    end
  end
end
