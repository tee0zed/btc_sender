# frozen_string_literal: true

RSpec.describe BtcSender::Blockchain do
  let(:client) { described_class.new(network: :signet) }

  describe '#get_utxos' do
    let(:address) { 'some_address' }
    let(:response) { [{ 'txid' => 'txid123', 'vout' => 0, 'value' => 10_000 }] }

    before do
      stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo")
        .to_return(status: 200, body: response.to_json)
    end

    it 'returns utxos for the given address' do
      result = client.get_utxos(address)

      expect(result.success?).to be true
      expect(result.body).to eq(response.to_json)
    end
  end

  describe '#get_tx' do
    let(:txid) { 'some_txid' }
    let(:response) { { 'txid' => txid, 'size' => 200, 'vin' => [], 'vout' => [] } }

    before do
      stub_request(:get, "https://mempool.space/signet/api/tx/#{txid}")
        .to_return(status: 200, body: response.to_json)
    end

    it 'returns transaction details for the given txid' do
      result = client.get_tx(txid)

      expect(result.success?).to be true
      expect(result.body).to eq(response.to_json)
    end
  end

  describe '#relay_tx' do
    let(:hex) { 'some_hex' }
    let(:response) { { success: true } }

    before do
      stub_request(:post, 'https://mempool.space/signet/api/tx')
        .with(body: hex)
        .to_return(status: 200, body: response.to_json)
    end

    it 'relays the transaction hex' do
      result = client.relay_tx(hex)

      expect(result.success?).to be true
      expect(result.body).to eq(response.to_json)
    end
  end

  context 'when request fails' do
    let(:address) { 'some_address' }
    let(:response) { { success: false } }

    context 'when request fails with 401' do
      before do
        stub_request(:get, "https://mempool.space/signet/api/address/#{address}/utxo")
          .to_return(status: 401, body: response.to_json)
      end

      it 'returns a failure response' do
        expect { client.get_utxos(address) }.to raise_error(BtcSender::ConnectionError)
      end
    end

    context 'when request fails with SockerError' do
      before do
        allow(described_class).to receive(:get).and_raise(SocketError)
      end

      it 'returns a failure response' do
        expect { client.get_utxos(address) }.to raise_error(BtcSender::ConnectionError)
      end
    end
  end
end
