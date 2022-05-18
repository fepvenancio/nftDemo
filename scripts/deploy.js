async function main() {

    const MoonNft = await ethers.getContractFactory("MoonNft")
    const moonNft = await MoonNft.deploy()
    await moonNft.deployed()
  
    console.log("Contract deployed to address:", moonNft.address)
  
  }

  main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  })