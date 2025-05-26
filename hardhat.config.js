const { vars } = require("hardhat/config");

require("@nomicfoundation/hardhat-chai-matchers");
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-toolbox");



/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    polygon : {
      url: "https://polygon-mainnet.g.allthatnode.com/full/evm/1fbd13b54dd24fb99a144ed409704dd7",
      accounts: [vars.get('PRIVATE_KEY')]
    }
  }
};
