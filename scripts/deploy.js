async function main() {

    const MoonNft = await ethers.getContractFactory("MoonNft")
    const moonNft = await MoonNft.deploy()
    await moonNft.deployed()
  
    console.log("Moon contract deployed to address:", moonNft.address)

    const StakeNft = await ethers.getContractFactory("StakingSystem")
    const stakeNft = await StakeNft.deploy()
    await stakeNft.deployed()
  
    console.log("Stake contract deployed to address:", stakeNft.address)

    const Whitelist = await ethers.getContractFactory("MoonNft")
    const whitelist = await Whitelist.deploy()
    await whitelist.deployed()
  
    console.log("Whitelist contract deployed to address:", whitelist.address)
  
  }

  main()
  .then(() => process.exit(0))
  .catch((error) => {
      console.error(error);
      process.exit(1);
  })