# Solana Contracts

This directory is where we keep programs (smart contracts) written for the purpose of transacting with ILOCK on the main Interlock DeSec network. The cost of transacting is low on Solana, so this is where the majority of the smart contract staking and earning ILOCK transfers will take place. Like Ethereum, Solana contracts will contain a token mint to mint ILOCK on the Solana chain, via the Token Program. Without getting into the mechanism, before ILOCK can be swapped or exchanged however, it must be passed through Wormhole to Ethereum to convert it to the ERC-20 standard. Client scripts will exist in each contract type's directory, which are used to validate and manipulate these contracts.