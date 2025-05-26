
import { HardhatUserConfig, vars } from "hardhat/config"
import "@nomicfoundation/hardhat-chai-matchers"
import "@nomicfoundation/hardhat-ethers"
import "@nomicfoundation/hardhat-toolbox"
import '@typechain/hardhat'


const config : HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    polygon : {
      url: vars.get('NODE_ENDPOINT'),
      accounts: [vars.get('PRIVATE_KEY')]
    }
  }
};

export default config