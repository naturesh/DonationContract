import { ethers } from "hardhat";
import { DonationContract__factory } from "../../typechain-types";
import { vars } from "hardhat/config";


const provider = new ethers.WebSocketProvider(
    vars.get('WEBSOCKET_ENDPOINT')
);

const contract = DonationContract__factory.connect(
    "0x2FbE6Cb5ceC319F54C5f478230dAFA251B4b8617",
    provider
)


console.log("Contract is connected.")

contract.on(contract.filters.CreateWalletEvent(), (owner, walletType, operationalPercent, timestamp, event) => {
  console.log("CreateWalletEvent", {
    owner,
    walletType,
    operationalPercent,
    timestamp,
    blockNumber: event.blockNumber,
    transactionHash: event.transactionHash
  });
});
