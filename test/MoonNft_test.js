const { assert } = require("chai");
const { ethers } = require("hardhat");

describe('MoonNft Contract', async () => {
	let nft
	let nftContractAddress
	let tokenId

	beforeEach('Setup Contract', async () => {
		const MoonNFTFactory = await ethers.getContractFactory('MoonNFT');
        [owner, addr1] = await ethers.getSigners();
		nft = await MoonNFTFactory.deploy();
		await nft.deployed();
		nftContractAddress = await nft.address;
	})

	it('Should have an address', async () => {
		assert.notEqual(nftContractAddress, 0x0)
		assert.notEqual(nftContractAddress, '')
		assert.notEqual(nftContractAddress, null)
		assert.notEqual(nftContractAddress, undefined)
	})

	it('Should have a name', async () => {
		const name = await nft.collectionName()

		assert.equal(name, '2 THE MOON');
	})

	it('Should have a symbol', async () => {
		const symbol = await nft.collectionSymbol()

		assert.equal(symbol, 'M00N');
	})

	it('Should be able to mint NFT', async () => {
        const account1 = addr1.address;
		let txn = await nft.safeMint(account1);
		let tx = await txn.wait();

		let event = tx.events[0];
		let value = event.args[2];
		tokenId = value.toNumber();

		assert.equal(tokenId, 0);
	})
})