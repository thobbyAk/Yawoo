const { assert } = require("chai");

let alice = "";

describe("MarketPlace", () => {
  beforeEach(async () => {
    this.MarketPlace = await ethers.getContractAt("MarketPlace");
    this.marketPlace = await this.MarketPlace.deploy();
    await this.marketPlace.deployed();
  });

  //test Emits event Market Item Created
  it("Creates a new item in marketplace", async () => {
    let tx = await this.marketPlace.createMarketItem(alice, "BRC", 10);
  });

  it("should not deposit 0", async () => {
    await expect(
      this.marketPlace.createMarketItem(alice, "BRC", 0)
    ).to.be.revertedWith("price must be at least 1 wei");
  });
});
