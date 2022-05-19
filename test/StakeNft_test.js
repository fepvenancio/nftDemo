const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('NFT Staking', function () {
  it('Mints, Whitelist and Stake an NFT', async () => {

    const MoonNFTFactory = await ethers.getContractFactory("MoonNFT");
    const StakingNFTFactory = await ethers.getContractFactory("StakingSystem");
          
    [owner, addr1] = await ethers.getSigners();
      
    const moonNftContract = await MoonNFTFactory.deploy();
    await moonNftContract.deployed();
    const moonNftContractAddress = moonNftContract.address;
    const stakingNftContract = await (await StakingNFTFactory.deploy(moonNftContractAddress));
    await stakingNftContract.deployed();
   
    account1 = addr1.address;
    deployer = owner.address;
    nullAddress = "0x0000000000000000000000000000000000000000";
      
    await expect(moonNftContract.setApprovalForAll(stakingNftContract.address, true))
      .to.emit(moonNftContract, "ApprovalForAll")
      .withArgs(deployer, stakingNftContract.address, true);
    //console.log("StakingSystem deployed: ", stakingNftContract.address);
    
    await expect(moonNftContract.safeMint(account1))
      .to.emit(moonNftContract, "Transfer")
      .withArgs(nullAddress, account1, 0);
     
    await stakingNftContract.connect(owner).initStaking();

    await expect(moonNftContract.connect(addr1).setApprovalForAll(stakingNftContract.address,true))
      .to.emit(moonNftContract, "ApprovalForAll")
      .withArgs(account1, stakingNftContract.address, true);

    const isWhitelisted = await stakingNftContract.isOnWhitelist(account1);
    console.log(isWhitelisted);
  
    await stakingNftContract.connect(owner).addOnWhitelist(account1);
      
    const isWhitelisted2 = await stakingNftContract.isOnWhitelist(account1);
    console.log(isWhitelisted2);
     
    await expect(stakingNftContract.connect(addr1).stake(0))
      .to.emit(stakingNftContract, "Staked")
      .withArgs(account1, 0);
      
    const getStakedTokens = await stakingNftContract.getStakedTokens(account1);
    console.log(getStakedTokens.toString());
  });
});