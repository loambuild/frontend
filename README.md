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

Using the `soroban contract init` variant will automatically install `loam-cli` using a `post-init` hook that we will add to soroban-cli as part of our initial grant.

The differentiating feature of Loam's frontend template: a declarative `environments.toml` configuration file ([example here](./environments.toml)). In this file, you describe the network settings, accounts, and contracts for each environment your team builds against. `loam-cli` handles the rest.

Aside from `loam init`, `loam-cli` will ship with two main commands:

1. `loam dev`
2. `loam build`

The most complex of these is `loam dev`. Let's break it down.

## `loam dev`

When you run this command, it will do everything everything in between having-contracts-created/deployed and running-the-frontend.

```text
contracts created/deployed <--      loam dev      --> frontend app
```

`loam dev` is the contract-dependencies-to-NPM-dependencies toolchain. It turns the contracts you depend on (contract dependencies) into frontend packages (NPM dependencies), getting your app to the point where it is ready to build or run with its own dev server, such as `astro dev`. (This template uses Astro, but `loam-cli` itself is agnostic to how you run your JavaScript frontend. It would work equally well with `next dev`, or with Svelte or Vue or any other JavaScript frontend tool.)

It will also watch your `contracts/*` directory and your `environments.toml` file for changes, and re-run your setup logic when things change.

Here's a full list of everything `loam dev` will do:

1. Default to `development` environment. This environment setting can be changed with either the `--env` flag or with the `LOAM_ENV` environment variable.

2. Inspect the `environments.toml` file and get things to the specified predictable starting state:


   ```mermaid
   flowchart TD
     A[loam dev] -->|network| B(run-locally?)
     B -->|yes| C[start]
     B -->|no| D[check]
     A -->|accounts| E(mainnet?)
     E -->|yes| F[check]
     E -->|no| G[create & fund]
     A -->|contracts| H(local?)
     H -->|yes| I(workspace = true?)
     I -->|yes| J[build, deploy, init]
     I -->|no| K[spoon]
     H -->|no| L[check]
     J --> M[bind & import]
     K --> M
     L --> M
   ```

   - connect to the specified network, or run it with `soroban network start`
   - create and/or fund accounts
     → on mainnet, will instead check that accounts exist and are funded
   - For specified contracts:
     - For an environment which uses a **local network**:
       - For contracts which have **`workspace = true`**:
         - **build** & **deploy** the contracts, saving the IDs so that on subsequent runs it can instead verify contracts are deployed and update them if needed.
         - **initialize** the contracts: runs any specified `init` commands (see `environments.toml` below)
       - [Beyond the scope of initial grant]: For contracts which instead specify an `environment`, `address`, and `at-ledger-sequence`:
         - **spoon** the specified contract's state, at time of specified ledger sequence, into the current environment's network.
     - For an environment which uses **futurenet**, **testnet**, **mainnet** or some other live network:
       - **check** that the contracts exist on that network. Note: Loam does not yet have plans to help with deploying the contracts. It only checks that you have successfully done so yourself.
     - For all environments:
       - **bind** the contracts
         - run `soroban contract bindings typescript` for each
         - save each generated library to gitignored `packages/*`, part of the [NPM workspace](https://docs.npmjs.com/cli/v10/using-npm/workspaces), using the name specified in `environments.toml`
         - **modify `networks` export** for each, to include all networks specified in `environments.toml`
       - **import** the contracts for use in the frontend. That is, create gitignored `src/contracts/*` files for each, which import the `Contract` class and `networks` object and export an instantiated version for the current environment's network.

3. Watch the `contracts/*` directory for changes, re-running all startup logic when anything changes, to make sure the frontend stays up-to-date with the contracts.

`loam build` flows easily out of this.


## `loam build`

This has the same behavior as `loam dev`, but defaults to `LOAM_ENV=production`. It also only runs once, rather than watching `contracts/*` for changes.

Note that Loam's convention and suggestion is that you build separate frontend apps for different environments. Given that a browser-extension wallet allows a user to switch networks, some dapps prefer to ship single frontends that can deal with multiple networks. Then, if a user selects Testnet in their wallet, the app will automatically switch to Testnet mode. We think this leads to more complicated development and error-prone user flows.

Instead, we suggest that you build one version of your frontend for mainnet and host it at, say, the root domain, `example.com`. Then build a separate version for testnet and host it at a separate domain, maybe `staging.example.com`. If a user to `example.com` has their Testnet wallet selected, you can present a warning and give them the option of visiting `staging.example.com`. Most users, of course, will only ever visit your production app.

This means that each frontend has separate contract dependencies, deployed on separate networks. These separate versions may differ! For example, a Testnet contract may have backdoors or other admin features that would not be safe for Mainnet. (You can use [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html) to compile separate versions of a contract for Testnet and Mainnet.) Let's think through how this would affect a frontend app, progressing from staging/Testnet to production/Mainnet environments:

1. First, when trying things in your staging environment, you will `LOAM_ENV=staging loam build`
   - This will fetch Testnet contracts and generate contract client NPM packages for them.
   - Then you can use `astro build` (or any other frontend build tool) to build your frontend.
2. Later, when you are ready to deploy to production, you will `loam build`, which defaults to `LOAM_ENV=production`
   - This will fetch your Mainnet contracts and generate NPM packages for them, _replacing the previous Testnet-targeting contract clients_.
   - At this point, when you `astro build` (or similar), your type-checker may complain that you are using methods that don't exist. That is, if you have strict TypeScript, which we strongly recommend!

How to fix those type errors? Easy. Add environment checks to your app, to only include certain routes or functionality in your staging & local versions. That is, check the value of `process.env.LOAM_ENV` or, if you're using newer, more-fully-ECMAscript Modules syntax, `import.meta.env.LOAM_ENV`.


# Milestones

Given the above, within our initial grant roadmap, we have the following milestones:

1. Create `loam-cli` with three subcommands:
   - `loam init`
   - `loam dev`
   - `loam build`
2. Update `soroban contract init` command to safely honor a `post-init` hook
   specified by the target `--frontend-template`, so that Loam's template can
   install `loam-cli`
3. Expand the `loambuild/template` frontend template to actually make use of its example
   `environments.toml`

In a future grant, we have the following milestone:

4. Allow specifying live contracts to spoon into local network
