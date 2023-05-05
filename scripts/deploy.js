const hre = require("hardhat");

async function main() {
  const MyNFT = await ethers.getContractFactory('MyNFT');
  const TokenWrapper = await ethers.getContractFactory('TokenWrapper');

  const myNFT = await MyNFT.deploy();
  await myNFT.deployed();
  console.log('MyNFT deployed to:', myNFT.address);

  const uniswapRouterAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
  const wrapper = await TokenWrapper.deploy(uniswapRouterAddress);
  await wrapper.deployed();
  console.log('TokenWrapper deployed to:', wrapper.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
