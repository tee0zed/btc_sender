RSpec.describe BtcSender::Engine do
  let(:key) { double('Key', to_addr: 'sender_address') }
  let(:blockchain) { double('Blockchain') }

  subject { described_class.new(key: key, blockchain: blockchain) }

  let(:utxos) do
    [
      { 'txid' => 'prev_tx_1', 'vout' => 0, 'value' => 60000, 'status' => { 'confirmed' => true } },
      { 'txid' => 'prev_tx_2', 'vout' => 1, 'value' => 70000, 'status' => { 'confirmed' => true } },
      { 'txid' => 'prev_tx_3', 'vout' => 0, 'value' => 80000, 'status' => { 'confirmed' => false } },
    ]
  end


  before do
    allow(blockchain).to receive(:get_utxos).with(key.to_addr).and_return(double('Response', parsed_response: utxos))
    allow(blockchain).to receive(:get_raw_tx).and_return('raw_tx')
  end

  describe '#raw_balance' do
    it 'calculates the raw balance correctly' do
      expect(subject.raw_balance).to eq(210000)
    end
  end

  describe '#spendable_balance' do
    it 'calculates the spendable balance correctly' do
      expect(subject.spendable_balance).to eq(130000)
    end
  end

  describe '#spendable_utxos' do
    it 'returns only spendable UTXOs' do
      expect(subject.spendable_utxos).to match_array(utxos.first(2))
    end
  end

  describe '#refresh_utxos' do
    it 'refreshes the UTXOs' do
      subject.refresh_utxos
      expect(blockchain).to have_received(:get_utxos).with(key.to_addr)
    end
  end

  describe '#send_funds!' do
    let(:to_address) { 'receiver_address' }
    let(:amount) { 50000 }
    let(:opts) { {} }

    let(:builder) { instance_double(BtcSender::TransactionBuilder, build_tx: true, sign_tx: true, tx: tx) }
    let(:tx) { double('Transaction') }

    before do
      allow(subject).to receive(:tx_builder).and_return(builder)
      allow(builder).to receive(:tx_payload).and_return('hex_payload')
      allow(blockchain).to receive(:relay_tx).and_return(true)
      allow(builder).to receive(:sign_tx).with(key).and_return(true)
    end

    it 'builds and sends funds successfully' do
      subject.send_funds!(to_address, amount, opts)

      expect(builder).to have_received(:build_tx)
      expect(builder).to have_received(:sign_tx).with(key)
      expect(blockchain).to have_received(:relay_tx).with('hex_payload')
    end
  end

  describe '#tx_builder' do
    let(:to_address) { 'receiver_address' }
    let(:amount) { 50000 }
    let(:opts) { {} }
    let(:builder) { instance_double(BtcSender::TransactionBuilder) }

    before do
      allow(BtcSender::TransactionBuilder).to receive(:new).and_return(builder)
      allow(subject).to receive(:utxos_by_strategy).with(:shrink, amount).and_return(utxos)
    end

    it 'creates a TransactionBuilder instance with correct parameters' do
      expect(subject.tx_builder(to_address, amount, opts)).to eq(builder)
      expect(subject).to have_received(:utxos_by_strategy).with(:shrink, amount)
      expect(BtcSender::TransactionBuilder).to have_received(:new).with(amount, to_address, key.to_addr, utxos: utxos, commission_multiplier: nil, blockchain: blockchain)
    end
  end
end
