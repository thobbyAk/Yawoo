const hre = require("hardhat");

async function main() {
	const MarketPlace = await hre.ethers.getContractFactory("MarketPlace");
	const marketPlace = await MarketPlace.deploy();

	await marketPlace.deployed();

	console.log("NFTMarket deployed to:", marketPlace.address);

	const Yawoo = await hre.ethers.getContractFactory("YawooToken");
	const yawoo = await Yawoo.deploy(marketPlace.address);
	await yawoo.deployed();

	console.log("NFT deployed to:", yawoo.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error);
		process.exit(1);
	});
