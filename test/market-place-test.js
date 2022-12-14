const { expect } = require("chai");
const { ethers } = require("hardhat");

let user = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";

describe("MarketPlace", function () {
	it("Should create and execute market sales", async function () {
		const Market = await ethers.getContractFactory("MarketPlace");
		const market = await Market.deploy();
		await market.deployed();
		const marketAddress = market.address;

		const Yawoo = await ethers.getContractFactory("YawooToken");
		const yawoo = await Yawoo.deploy(marketAddress);
		await yawoo.deployed();
		const nftContractAddress = yawoo.address;

		let listingPrice = await market.getListingPrice();
		listingPrice = listingPrice.toString();

		const auctionPrice = ethers.utils.parseUnits("100", "ether");

		/* create two tokens */
		await yawoo.mintToken("https://www.mytokenlocation.com");
		await yawoo.mintToken("https://www.mytokenlocation2.com");

		/* put both tokens for sale */
		await market.createMarketItem(nftContractAddress, 1, auctionPrice, {
			value: listingPrice,
		});
		await market.createMarketItem(nftContractAddress, 2, auctionPrice, {
			value: listingPrice,
		});

		const [_, buyerAddress] = await ethers.getSigners();

		/* execute sale of token to another user */
		await market
			.connect(buyerAddress)
			.createMarketSale(nftContractAddress, 1, { value: auctionPrice });

		/* query for and return the unsold items */
		items = await market.fetchMarketitems();
		items = await Promise.all(
			items.map(async (i) => {
				const tokenUri = await yawoo.tokenURI(i.tokenId);
				let item = {
					price: i.price.toString(),
					tokenId: i.tokenId.toString(),
					seller: i.seller,
					owner: i.owner,
					tokenUri,
				};
				return item;
			})
		);
		console.log("items:", items);
	});
	it("should be able to supply collateral to factory contract and factory supplies to compound", async function () {
		const Market = await ethers.getContractFactory("MarketPlace");
		const market = await Market.deploy();
		await market.deployed();
		const marketAddress = market.address;

		const Yawoo = await ethers.getContractFactory("YawooToken");
		const yawoo = await Yawoo.deploy(marketAddress);
		await yawoo.deployed();

		const Factory = await ethers.getContractFactory("Factory");
		const factory = await Factory.deploy();
		await factory.deployed();
		const factoryAddress = factory.address;
		const provider = await ethers.getDefaultProvider();
		console.log("getting here");
		const [_, userAddress] = await ethers.getSigners();
		const getUserBalance = await provider.getBalance(userAddress.address);
		const getFactoryBalance = await provider.getBalance(factoryAddress);
		console.log("factory Balance before", getFactoryBalance);
		const amount = ethers.utils.parseUnits("100", "ether");
		await factory.receive({
			value: amount,
		});
		console.log("factory Balance", getFactoryBalance);
		console.log("factoryBalance", await provider.getBalance(factoryAddress));
		await provider.getBalance(factoryAddress);
		const amountToSend = ethers.utils.parseUnits("10", "ether");

		const supplied = await market.supplyCollateral(amount);
		console.log("supplied", supplied);
	});
});
