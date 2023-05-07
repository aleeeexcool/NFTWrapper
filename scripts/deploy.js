const hre = require("hardhat");

async function main() {
  const NFTWrapper = await ethers.getContractFactory('NFTWrapper');

  const wrapper = await NFTWrapper.deploy();
  await wrapper.deployed();
  console.log('NFTWrapper deployed to:', wrapper.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
