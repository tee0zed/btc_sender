# frozen_string_literal: true

describe BtcSender::TransactionBuilder do
  let(:utxos) do
    [{
      'txid' => '53058ad2be32b47dd722b6ab43ea9bdb84f5202eb04945835523410480bc9cd1',
      'vout' => 1,
      'raw_tx' => raw_tx,
      'status' => { 'confirmed' => true, 'block_height' => 2_578_542,
                    'block_hash' => '000000000000000c03249d6b15f6441f6227418207d37cf3549b90db0b29b7ab', 'block_time' => 1_708_260_900 },
      'value' => balance
    }]
  end

  let(:balance) { 4_000_000 }
  let(:amount) { 3_000_000 }
  let(:recipient) { 'mv4rnyY3Su5gjcDNzbMLKBQkBicCtHUtFB' }
  let(:sender) { 'msT2GFQnXWTyf3r3MXBHw4sFV1jcUG4o12' }
  let(:blockchain) { instance_double(BtcSender::Blockchain) }
  let(:options) { { utxos: utxos, blockchain: blockchain } }
  let(:raw_tx) { Base64.decode64(File.read('spec/support/fixtures/raw_tx')) }
  let(:commission) { 100 }

  subject(:builder) { described_class.new(amount, recipient, sender, options) }

  before do
    allow(builder).to receive(:commission).and_return(commission)
  end

  describe '#build_tx' do
    context 'when the balance is greater than the sum of amount and commission' do
      it 'builds the correct transaction' do
        expect(builder.build_tx).to be_a(BtcSender::TransactionBuilder)
        expect(builder.tx).to be_a(Bitcoin::Tx)
        expect(builder.tx.in.size).to eq(1)
        expect(builder.tx.out.size).to eq(2)
      end

      it 'calculates the correct commission' do
        builder.build_tx
        expect(builder.tx.out[1].value).to eq(balance - amount - commission)
      end
    end

    context 'when the balance is less than the sum of amount and commission' do
      let(:amount) { balance * 2 }
      it 'raises an InsufficientFundsError' do
        expect { builder.build_tx }.to raise_error(BtcSender::InsufficientFundsError)
      end
    end
  end

  describe '#sign_tx' do
    let(:private_key) do
      instance_double(BtcSender::Key, to_address: Bitcoin::Key.generate.to_addr, sign: 'signature', pubkey: 'pubkey')
    end

    before do
      builder.build_tx
    end

    context 'when transaction is built' do
      it 'signs the transaction and verifies signatures' do
        expect { subject.sign_tx(private_key) }.not_to raise_error
        subject.tx.in.each do |input|
          expect(input.script_sig.chunks).not_to be_empty
        end
      end
    end
  end
end
