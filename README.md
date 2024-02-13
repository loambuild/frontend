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

# Architecture

The Loam architecture will consist of two main elements:

1. `loam-cli`
2. The frontend template

The frontend template can be generated two ways:

- `loam init`
- `soroban contract init [project-name] --frontend-template https://github.com/loambuild/template`

Using the `soroban contract init` variant will automatically install `loam-cli`
using a `post-init` hook that we will add to soroban-cli as part of our initial
grant.

The differentiating feature of Loam's frontend template: a declarative
`environments.toml` configuration file. In this file, you describe the network
settings, accounts, and contracts for each environment your team builds
against. `loam-cli` handles the rest.

Check out [an example `environments.toml` here](./environments.toml).

Aside from `loam init`, `loam-cli` will ship with two main commands:

1. `loam dev`
2. `loam build`

The most complex of these is `loam dev`. Let's break it down.

## `loam dev`

1. Defaults to `development` environment. This environment setting can be
   changed with either the `--env` flag or with the `LOAM_ENV` environment
   variable.

2. Inspects the `environments.toml` file and gets things to the specified
   predictable starting state:

   - starts the specified network
   - creates and/or funds accounts
     → on mainnet, will instead check that accounts exist and are funded
   - For specified contracts:
     - For an environment which uses a **local network**:
       - For contracts which have **`workspace = true`**:
         - **build** & **deploy** the contracts, saving the IDs so that on
           subsequent runs it can instead 
           verify contracts are deployed and update them if needed.
         - **initialize** the contracts: runs any specified `init` commands
           (see `environments.toml` below)
       - [Beyond the scope of initial grant]: For contracts which instead
         specify an `environment`, `address`, and `at-ledger-sequence`:
         - **spoon** the specified contract's state, at time of specified
           ledger sequence, into the current environment's network.
     - For an environment which uses **futurenet**, **testnet**, **mainnet**
       or some other live network:
       - **check** that the contracts exist on that network. Note: Loam does
         not yet have plans to help with deploying the contracts. It only
         checks that you have successfully done so yourself.
     - For all environments:
       - **bind** the contracts
         - run `soroban contract bindings typescript` for each
         - save each generated library to gitignored `packages/*`, part of the
           [NPM workspace](https://docs.npmjs.com/cli/v10/using-npm/workspaces),
           using the name specified in `environments.toml`
         - **modify `networks` export** for each, to include all networks
           specified in `environments.toml`
       - **import** the contracts for use in the frontend. That is, create
         gitignored `src/contracts/*` files for each, which import the
         `Contract` class and `networks` object and export an instantiated
         version for the current environment's network.

3. Watch the `contracts/*` directory for changes, re-running all startup
   logic when anything changes, to make sure the frontend stays up-to-date
   with the contracts.

This gets the frontend server ready to run. If using strict TypeScript, it also
means the frontend logic will be type-checked against the contract clients
generated for the given environment. If a production contract is slightly
different than a development/staging contract but has the same name, app
authors will need to add `LOAM_ENV` checks to their app logic, and build &
deploy separate frontends for each environment.

`loam build` flows easily out of this.


## `loam build`

This has the same behavior as `loam dev`, but defaults to
`LOAM_ENV=production`. It also only runs once, rather than watching
`contracts/*` for changes


# Milestones

Given the above, within our initial grant roadmap, we have the following milestones:

1. Create `loam-cli` with three subcommands:
   - `loam init`
   - `loam dev`
   - `loam build`
2. Update `soroban contract init` command to safely honor a `post-init` hook
   specified by the target `--frontend-template`, so that Loam's template can
   install `loam-cli`
3. Expand the `loambuild/template` frontend template to include an example
   `environments.toml`

In a future grant, we have the following milestone:

4. Allow specifying live contracts to spoon into local network
