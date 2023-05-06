const hre = require("hardhat");

async function main() {
  const TokenWrapper = await ethers.getContractFactory('TokenWrapper');

  const wrapper = await TokenWrapper.deploy();
  await wrapper.deployed();
  console.log('TokenWrapper deployed to:', wrapper.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
