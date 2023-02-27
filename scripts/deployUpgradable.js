// scripts/deploy.js
const {ethers} = require("hardhat");
const { run } = require("hardhat");
const {
VerifywithArgs,Verify} = require("../verifyfunc");

async function main() {
  const address = ["0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7"];
const addressObj = { kind: address };

  const CrowdFunding = await ethers.getContractFactory("CrowdFunding");
  console.log("Deploying CrowdFunding...");
  const crowdFunding = await upgrades.deployProxy(CrowdFunding, address,{ initializer: 'initialize' });
  console.log("CrowdFunding  deployed to:", crowdFunding.address);
  await Verify(crowdFunding.address);

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });