const { ethers } = require("hardhat");

async function main() {
    const DonationContract = await ethers.getContractFactory("DonationContract")

    console.log("Deploying DonationContract...")
    const contract = await DonationContract.deploy()
    await contract.waitForDeployment()

    console.log("DonationContract deployed to:", contract.target)

    const baseURI = 'https://example.com/'

    console.log("Setting baseURI...")
    const tx = await contract.setBaseURI(baseURI)
    await tx.wait()

    console.log("baseURI is :", baseURI)


}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

