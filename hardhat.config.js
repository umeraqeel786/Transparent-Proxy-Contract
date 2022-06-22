require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require('@openzeppelin/hardhat-upgrades');
require('@nomiclabs/hardhat-etherscan')
require('dotenv').config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const RINKEBY_RPC_URL= process.env.RINKEBY_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
  defaultNetwork: "rinkeby",
   networks:{
     rinkeby:{
         url:RINKEBY_RPC_URL,
         accounts:[PRIVATE_KEY]
     }
   },
   solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
   },
   etherscan:{
             apiKey:ETHERSCAN_API_KEY
   },
};
