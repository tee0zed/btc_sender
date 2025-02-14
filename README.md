# BtcSender

This is a simple bitcoin sender that uses the blockstream.info API to send bitcoins to a given address.

## Installation
Put the wif.txt file in the root of the project and run the following command:
```bash
bin/btc_sender
```

If the wif.txt file is not present, the program will generate a new one.

## Usage
- You can choose between consolidating all the UTXOs in the wallet or sending a specific amount to a given address during transaction.
- You can see spendable outputs and the raw balance of the wallet.
- You can adjust the fee rate. (The default is 2 sat/vB). Commission calculation is based on the size of the transaction in vB.
- You can restore WIF from the any absolute path. Just run the following command:
```bash
bin/btc_sender --path /path/to/wif.txt
```

- You can use the signet. Just run the following command:
```bash
bin/btc_sender --signet
```

## Docker

You can also run the program using docker. Just run the following command:
```bash
docker build -t btc_sender .
docker run --rm -it btc_sender
bin/btc_sender --signet
```
