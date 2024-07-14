# Loam's Frontend Template for Soroban, using Astro

Under active development.

Goals:

- [x] For all contracts in `contracts/*`, automatically deploy to testnet, generate bindings, and import in `src/contracts/*`.
- [ ] Make it just as easy to rely on 3rd-party, already-deployed contracts
- [ ] Support multiple contract environments
  - [x] development/local ("standalone")
  - [ ] testing/local
  - [ ] staging/testnet
  - [ ] production/mainnet

# Getting Started

- `cp .env.example .env`
- `npm install`
- `npm run dev`
