require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** Team1 Kenya - Mini Hack Cohort 2 - Session 3
 *  Networks: hardhat (local tests) and fuji (Avalanche testnet, chainId 43113)
 */
module.exports = {
  solidity: "0.8.24",
  networks: {
    fuji: {
      url: process.env.FUJI_RPC_URL || "https://api.avax-test.network/ext/bc/C/rpc",
      chainId: 43113,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    // Snowtrace (Routescan) accepts any non-empty API key for Fuji verification
    apiKey: { avalancheFujiTestnet: "verifyContract" },
    customChains: [
      {
        network: "avalancheFujiTestnet",
        chainId: 43113,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/testnet/evm/43113/etherscan",
          browserURL: "https://testnet.snowtrace.io",
        },
      },
    ],
  },
};
