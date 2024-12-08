

# Requirements installation
### Setup Enviroment
- This currently runs on a localblock chain using wsl and using foundry.
To install wsl type this command in CMD or you can [read more](installation-readme/README.md).
```bash
wsl --install
```

- installation for foundry into wsl
```bash
curl -L https://foundry.paradigm.xyz
```

- installation for testing libary package
```bash
forge install foundry-rs/forge-std.git@1.9.4 --no-commit
```

- installation for getting price feed from the chain [link](https://docs.chain.link/data-feeds/using-data-feeds)
```bash
forge install smartcontractkit/chainlink-brownie-contracts@1.3.0 --no-commit
```

