# Loam's Frontend Template for Soroban, using Astro

Under active development.

Goals:

- [ ] Seamless dependencies for project's own contract as well as 3rd-party, already-deployed contracts
- [ ] Support multiple contract environments
  - [x] development/local ("standalone")
  - [ ] testing/local
  - [ ] staging/testnet
  - [ ] production/mainnet
- [ ] Simple template-development to template-readiness pipeline, probably with a CI script to automatically:
  - [ ] remove `soroban init` artifacts like `contracts` folder
  - [ ] rewrite `README.md` and `gitignore` to get them into a state that's ready to be merged with those from `soroban init`
  - [ ] push all of this to the `main` branch, meaning we need to do template development/improvement from a `dev` branch or something
