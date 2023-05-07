const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTWrapper", function () {
  let contract;
  let token;
  let owner;
  let user;
  let unallowedToken = "0x0000000000000000000000000000000000000000";

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    const MyToken = await ethers.getContractFactory("MyToken");
    token = await MyToken.deploy(10000);

    const NFTWrapper = await ethers.getContractFactory("NFTWrapper");
    contract = await NFTWrapper.deploy();

    await contract.addToken(token.address);
  });

  describe("wrapTokens()", function () {
    it("should wrap tokens", async function () {
      const initialBalance = await token.balanceOf(owner.address);

      await token.connect(owner).approve(contract.address, 50);
      await contract.connect(owner).wrapTokens(token.address, 50);

      const tokenId = 0;
      const tokenAmount = await contract.getWrappedTokenAmount(tokenId);
      const balance = await token.balanceOf(contract.address);
      const ownerOfToken = await contract.ownerOf(tokenId);

      expect(tokenAmount).to.equal(50);
      expect(balance).to.equal(50);
      expect(ownerOfToken).to.equal(owner.address);
      expect(await token.balanceOf(owner.address)).to.equal(initialBalance.sub(50));
    });

    it("should not allow wrapping of unallowed tokens", async function () {
      await expect(contract.connect(user).wrapTokens(unallowedToken, 50)).to.be.revertedWith("Token not allowed");
    });

    it("should not allow wrapping of zero tokens", async function () {
      await expect(contract.connect(user).wrapTokens(token.address, 0)).to.be.revertedWith("Amount must be greater than zero");
    });
  });

  describe("unwrapTokens()", function () {
    it("should emit a TokensUnwrapped event when function unwrapTokens is called", async function () {
      await token.connect(owner).approve(contract.address, 50);
      await contract.connect(owner).wrapTokens(token.address, 50);

      const tokenId = 0;

      await contract.connect(owner).unwrapTokens(token.address, tokenId);

      const event = receipt.events.find(
        (event) => event.event === "TokensUnwrapped"
      );

      expect(event.args.tokenAddress).to.equal(token.address);
      expect(event.args.sender).to.equal(owner.address);
      expect(event.args.amount).to.equal(50);
      expect(event.args.tokenId).to.equal(tokenId);
    });

    it("should not allow unwrapping of unallowed tokens", async function () {
      await token.connect(owner).approve(contract.address, 100);
      await contract.connect(owner).wrapTokens(token.address, 50);
      const tokenId = 0;

      await expect(contract.connect(owner).unwrapTokens(unallowedToken, tokenId)).to.be.revertedWith("Token not allowed");
    });

    it("should not allow unwrapping of tokens by non-owner", async function () {
      await token.connect(owner).approve(contract.address, 100);
      await contract.connect(owner).wrapTokens(token.address, 50);

      await expect(contract.connect(user).unwrapTokens(token.address, 0)).to.be.revertedWith("Sender does not own this NFT");
    });
  });
});

