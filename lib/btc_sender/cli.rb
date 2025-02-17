require_relative '../btc_sender'
require_relative 'entities/bitcoin'

module BtcSender
  class CLI
    attr_accessor :engine
    def initialize(engine:)
      @engine = engine
    end

    def run
      loop do
        display_menu
        handle_menu
      end
    end

    private

    def display_menu
      puts "1. Spendable balance"
      puts "2. Raw balance"
      puts "3. Send funds"
      puts "4. Address info"
      puts "5. Exit"
    end

    def handle_menu
      case STDIN.gets.chomp.to_i
      when 1
        show_balance
      when 2
        show_raw_balance
      when 3
        send_funds
      when 4
        show_info
      when 5
        exit
      end
    end

    def show_info
      within_window do
        puts "Address: #{engine.key.to_address}"
        puts "Network: #{Bitcoin.chain_params.network}"
      end
    end

    def show_raw_balance
      within_window do
        engine.refresh_utxos

        btc = Entities::Bitcoin.new(engine.raw_balance)
        puts "Raw balance: #{btc.inspect}"
        engine.utxos.each do |utxo|
          puts "#{utxo['txid']} - #{utxo['value']}: #{utxo['status']['confirmed'] ? 'confirmed' : 'unconfirmed'}"
        end
      end
    end

    def show_balance
      within_window do
        engine.refresh_utxos

        btc = Entities::Bitcoin.new(engine.spendable_balance)
        puts "Spendable balance: #{btc.inspect}"
        engine.spendable_utxos.each do |utxo|
          puts "#{utxo['txid']} - #{utxo['value']}: #{utxo['status']['confirmed'] ? 'confirmed' : 'unconfirmed'}"
        end
      end
    end

    def send_funds
      within_window do
        print "Enter receiver address: "
        to = validatable_input(validation: ->(input) { input.size > 25 })

        print "Enter amount: "
        amount = validatable_input(validation: ->(input) { input.to_i > 0 })

        print "Enter commission multiplier, default is 1: "
        commission_multiplier = validatable_input(validation: ->(input) { input.to_f > 0 && input.to_f.round(1) == input.to_f })

        print "Do you want to consolidate all addresses UTXOs or use the fewest?: (0/1) "
        strategy_input = validatable_input(validation: ->(input) { [0, 1].include?(input.to_i) })
        strategy = strategy_input.to_i == 0 ? :shrink : :fewest

        puts
        puts
        puts "txID: #{engine.send_funds!(to, normalized_amount(amount), commission_multiplier: commission_multiplier, strategy: strategy)}"
      end
    end

    def normalized_amount(input)
      input.match?(/\./) ? input.to_f * 100_000_000 : input.to_i
    end

    def validatable_input(validation:)
      input = STDIN.gets.chomp

      until validation.call(input)
        print "Invalid input, try again: "
        exit if input.chomp == "exit"
        input = STDIN.gets.chomp
      end

      input
    end

    def within_window
      system('clear') || system('cls')

      puts
      puts
      yield
      puts
      puts
    end
  end
end
