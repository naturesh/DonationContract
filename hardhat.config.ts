
import { HardhatUserConfig, vars } from "hardhat/config"
import "@nomicfoundation/hardhat-chai-matchers"
import "@nomicfoundation/hardhat-ethers"
import "@nomicfoundation/hardhat-toolbox"
import '@typechain/hardhat'


const config : HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    polygon : {
      url: "https://polygon-mainnet.g.allthatnode.com/full/evm/1fbd13b54dd24fb99a144ed409704dd7",
      accounts: [vars.get('PRIVATE_KEY')]
    }
  }
};

export default config