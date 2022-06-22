// scripts/deploy.js
async function main() {
    const DroneContract = await ethers.getContractFactory("DroneContract");
    console.log("Deploying DroneContract...");
    const DroneContractProxy = await upgrades.deployProxy(DroneContract, [10], { initializer: 'initialize' });
    console.log("DroneContractProxy deployed to:", DroneContractProxy.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });