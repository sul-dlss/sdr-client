# frozen_string_literal: true

RSpec.describe SdrClient::Deposit do
  describe '.run' do
    let(:process) { instance_double(SdrClient::Deposit::Process, run: true) }
    let(:request) { instance_double(SdrClient::Deposit::Request, with_file_sets: second_request) }
    let(:second_request) { instance_double(SdrClient::Deposit::Request, as_json: {}) }

    before do
      allow(SdrClient::Credentials).to receive(:read).and_return('token')
      allow(SdrClient::Deposit::Request).to receive(:new).and_return(request)
      allow(SdrClient::Deposit::Process).to receive(:new).and_return(process)
    end

    context 'without a grouping_strategy' do
      subject(:run) do
        described_class.run(apo: 'druid:bc123df4567',
                            collection: 'druid:gh123df4567',
                            source_id: 'googlebooks:12345',
                            url: 'http://example.com/')
      end

      it 'runs the process with the default grouping_strategy' do
        run
        expect(SdrClient::Deposit::Process).to have_received(:new)
          .with(grouping_strategy: SdrClient::Deposit::SingleFileGroupingStrategy,
                files: [],
                metadata: request,
                token: 'token',
                url: 'http://example.com/')

        expect(process).to have_received(:run)
      end
    end

    context 'with a grouping_strategy' do
      subject(:run) do
        described_class.run(apo: 'druid:bc123df4567',
                            collection: 'druid:gh123df4567',
                            source_id: 'googlebooks:12345',
                            url: 'http://example.com/',
                            grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy)
      end

      it 'runs the process with the specified grouping_strategy' do
        run
        expect(SdrClient::Deposit::Process).to have_received(:new)
          .with(grouping_strategy: SdrClient::Deposit::MatchingFileGroupingStrategy,
                files: [],
                metadata: request,
                token: 'token',
                url: 'http://example.com/')

        expect(process).to have_received(:run)
      end
    end
  end
end
