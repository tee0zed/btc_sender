module Bitcoin
  extend self

  NETWORKS[:signet] = NETWORKS[:testnet3].merge({
    magic_head: "\x0A\x03\xCF\x40",
    address_version: "6f",
    p2sh_version: "c4",
    bech32_hrp: "tb",
    privkey_version: "ef",
    default_port: 38333,
    genesis_hash: "00000008819873e925422c1ff0f99f7cc9bbb232af63a077a480a3633bee1ef6",
    extended_privkey_version: "04358394",
    extended_pubkey_version: "043587cf",
    proof_of_work_limit: 0x1d00ffff,
    dns_seeds: [
      "seed.signet.bitcoin.sprovoost.nl",
      "seed.signet.achownodes.xyz",
      "electrum.signet.secp256k1.org",
      "signet-seed.bitcoin.sprovoost.nl",
      "signet-seed.bitcoin.mindetach.com"
    ],
    known_nodes: [],
    checkpoints: {}
  })

  def bitcoin_elliptic_curve
    # OpenSSL::PKey::EC.new("secp256k1").generate_key doesn't work in OpenSSL 3.0.0 bc keys are immutable
    ::OpenSSL::PKey::EC.generate("secp256k1")
  end

  def generate_key
    inspect_key(bitcoin_elliptic_curve)
  end
end


