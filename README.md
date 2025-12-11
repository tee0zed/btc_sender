# BtcSender

This is a simple bitcoin sender that uses the blockstream.info API to send bitcoins to a given address.
Put my head on that it is been written by my hand.

## Installation
App will take wif string either from `ENV['WIF']` ENV, or from a file named `wif.txt` in the root of the project.

```bash
bin/btc_sender
```

If neither `ENV['WIF']`, neither `wif.txt` file is not present, the program will generate a new one and save it to root direcotry.
If root directory contains some sort of wif file (filename matching `*wif*` pattern), the program will safely save the new wif 
with unique timestamp to avoid overwriting. 

## Usage
- You can choose between consolidating all the UTXOs in the wallet or sending a specific amount to a given address during transaction.
- You can see spendable outputs and the raw balance of the wallet.
- You can adjust the fee rate. (The default is 2 sat/vB). Commission calculation is based on the size of the transaction in vB.
- You can restore WIF from any absolute path. Just run the following command, or you can restore it from `ENV['WIF']` string.
```bash
bin/btc_sender --path /path/to/wif.txt
```


- You can use the signet, testnet or mainnet. Just run the following command:
```bash
bin/btc_sender --signet

bin/btc_sender --testnet

bin/btc_sender # mainnet
```

## Docker

You can also run the program using docker. Just run the following command:
```bash
docker build -t btc_sender .
docker run --rm -it btc_sender
bin/btc_sender
```
