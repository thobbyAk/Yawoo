const { assert } = require("chai");

let alice = "";

describe("Factory", () => {
  beforeEach(async () => {
    this.Factory = await ethers.getContractFactory("Factory");
    this.factory = await this.Factory.deploy();
    await this.factory.deployed();
  });

  //test Emits event Assets Minted To Compound
  it("Mints assets to compound", async () => {
    let tx = await this.factory.mintAssetsToCompound(alice, 10);
  });

  it("should not deposit 0", async () => {
    await expect(
      this.this.factory.mintAssetsToCompound(alice, 10)
    ).to.be.revertedWith("amount must be grater than 0");
  });
});
