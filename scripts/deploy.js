const hre = require("hardhat");

async function main() {
  const NFTWrapper = await ethers.getContractFactory('NFTWrapper');
  const wrapper = await NFTWrapper.deploy();
  await wrapper.deployed();

  const MyToken = await ethers.getContractFactory('MyToken');
  const token = await MyToken.deploy(10000);
  await token.deployed();

  console.log('NFTWrapper deployed to:', wrapper.address);
  console.log('MyToken deployed to:', token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
