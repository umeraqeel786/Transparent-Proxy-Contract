// scripts/prepare_upgrade.js
async function main() {
    const proxyAddress = '0x9434F19aE3CD65caB66c85F887e4af82ac0A76fF';
   
    const DroneContractV2 = await ethers.getContractFactory("DroneContractV2");
    console.log("Preparing upgrade...");
    const DroneContractV2Proxy = await upgrades.upgradeProxy(proxyAddress, DroneContractV2);
    console.log("DroneContractV2Proxy deployed to:", DroneContractV2Proxy.address);
  }
   
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });