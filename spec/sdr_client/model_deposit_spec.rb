# frozen_string_literal: true

RSpec.describe SdrClient::Deposit do
  describe '.run_model' do
    subject(:run) do
      described_class.model_run(files: files, request_dro: request_dro,
                                url: upload_url, accession: true, priority: 'low')
    end

    let(:process) { instance_double(SdrClient::Deposit::ModelProcess, run: true) }

    let(:files) { ['spec/fixtures/file1.txt'] }

    let(:request_dro) { build(:request_dro) }
    let(:connection) { instance_double(SdrClient::Connection) }
    let(:upload_url) { 'http://localhost:3000/v1/disk/GpscGFUTmxO' }

    before do
      allow(SdrClient::Connection).to receive(:new).and_return(connection)
      allow(SdrClient::Deposit::ModelProcess).to receive(:new).and_return(process)
    end

    it 'runs the process' do
      run
      expect(SdrClient::Connection).to have_received(:new).with(url: upload_url)

      expect(SdrClient::Deposit::ModelProcess).to have_received(:new)
        .with(files: files,
              request_dro: request_dro,
              connection: connection,
              logger: Logger,
              accession: true,
              priority: 'low')

      expect(process).to have_received(:run)
    end
  end
end
