const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

let moonNftContract
let stakingNftContract
let deployer
let deployerAddress
let account1
let account1Address
let account2
let account2Address
let nullAddress

beforeEach('Deploy contracts, create accounts and approve', async () => {
  const MoonNFTFactory = await ethers.getContractFactory("MoonNFT");
  const StakingNFTFactory = await ethers.getContractFactory("StakingSystem");
          
  [owner, addr1, addr2] = await ethers.getSigners();
      
  moonNftContract = await MoonNFTFactory.deploy();
  await moonNftContract.deployed();
  const moonNftContractAddress = moonNftContract.address;
  stakingNftContract = await (await StakingNFTFactory.deploy(moonNftContractAddress));
  await stakingNftContract.deployed();
  
  deployer = owner;
  deployerAddress = owner.address;
  account1 = addr1;
  account1Address = addr1.address;
  account2 = addr2;
  account2Address = addr2.address;
  nullAddress = "0x0000000000000000000000000000000000000000";

  await expect(moonNftContract.setApprovalForAll(stakingNftContract.address, true))
    .to.emit(moonNftContract, "ApprovalForAll")
    .withArgs(deployerAddress, stakingNftContract.address, true);

  await expect(moonNftContract.connect(addr1).setApprovalForAll(stakingNftContract.address,true))
    .to.emit(moonNftContract, "ApprovalForAll")
    .withArgs(account1Address, stakingNftContract.address, true);
  
  await expect(moonNftContract.connect(addr2).setApprovalForAll(stakingNftContract.address,true))
    .to.emit(moonNftContract, "ApprovalForAll")
    .withArgs(account2Address, stakingNftContract.address, true);
})

describe('NFT Minting, Initialising the pool and staking', async () => {
  it('Mints an NFT for each account', async () => {
    
    //console.log("StakingSystem deployed: ", stakingNftContract.address);
    
    await expect(moonNftContract.safeMint(account1Address))
      .to.emit(moonNftContract, "Transfer")
      .withArgs(nullAddress, account1Address, 0);
    
    await expect(moonNftContract.safeMint(account2Address))
      .to.emit(moonNftContract, "Transfer")
      .withArgs(nullAddress, account2Address, 1);
  })

  it('The owner initializes the pool', async () => {
    await stakingNftContract.connect(deployer).initStaking();
    assert.equal(deployer, deployer);
  })

  it('An account not the owner tries to initialize it', async () => {
    await expect(stakingNftContract.connect(account1).initStaking()).to.be.revertedWith("Ownable: caller is not the owner");
  })

  it('Deployer adds an account to the whitelist', async () => {
    await stakingNftContract.connect(deployer).addOnWhitelist(account1Address);
  })

  it('Try to add an account to the whitelist without being the owner', async () => {
    await expect(stakingNftContract.connect(account1).addOnWhitelist(account1Address)).to.be.revertedWith("Ownable: caller is not the owner");
  })
})

describe('Staking', async () => {
  beforeEach('Start Staking and add account1 to the whitelist', async () => {
    await stakingNftContract.connect(deployer).initStaking();
    await stakingNftContract.connect(deployer).addOnWhitelist(account1Address);
    await expect(moonNftContract.safeMint(account1Address))
      .to.emit(moonNftContract, "Transfer")
      .withArgs(nullAddress, account1Address, 0);
    
    await expect(moonNftContract.safeMint(account2Address))
      .to.emit(moonNftContract, "Transfer")
      .withArgs(nullAddress, account2Address, 1);
  })

  it('Account1 and Account2 try to stake (account1 whitelisted)', async () => {
    await expect(stakingNftContract.connect(account1).stake(0))
      .to.emit(stakingNftContract, "Staked")
      .withArgs(account1Address, 0);
    
    await expect(stakingNftContract.connect(account2).stake(1))
      .to.be.revertedWith("member must be on the whitelist")
  })
})

describe('Unstaking', async () => {
  beforeEach('Inits mints and adds NFT to whitelist', async () => { 
    await expect(moonNftContract.safeMint(account1Address))
      .to.emit(moonNftContract, "Transfer")
      .withArgs(nullAddress, account1Address, 0);
    
    await expect(moonNftContract.safeMint(account2Address))
      .to.emit(moonNftContract, "Transfer")
      .withArgs(nullAddress, account2Address, 1);
    
    await stakingNftContract.connect(deployer).initStaking();
    await stakingNftContract.connect(deployer).addOnWhitelist(account1Address);
    await stakingNftContract.connect(deployer).addOnWhitelist(account2Address);

    await expect(stakingNftContract.connect(account1).stake(0))
      .to.emit(stakingNftContract, "Staked")
      .withArgs(account1Address, 0);
    
    await expect(stakingNftContract.connect(account2).stake(1))
      .to.emit(stakingNftContract, "Staked")
      .withArgs(account2Address, 1);
  })

  it('Unstaking the NFT (account1 whitelisted)', async () => {
    await expect(stakingNftContract.connect(account1).unstake(0))
      .to.emit(stakingNftContract, "Unstaked")
      .withArgs(account1Address, 0);  
  })

  it('stops the pool and unstakes (wrong NFT Id)', async () => {
    await expect(stakingNftContract.connect(deployer).stopStakingUnstake(account1Address, 1))
      .to.be.revertedWith("member must be the owner of the staked nft");
  })

  it('stops the pool and unstakes', async () => {
    await expect(stakingNftContract.connect(deployer).stopStakingUnstake(account1Address, 0))
      .to.emit(stakingNftContract, "Unstaked")
      .withArgs(account1Address, 0)
  })

  it('stops the pool and unstakes all', async () => {
    const stakedTokens1 = await stakingNftContract.getStakedTokens(account1Address);
      assert.equal(stakedTokens1.length, 1);

    const stakedTokens2 = await stakingNftContract.getStakedTokens(account2Address);
      assert.equal(stakedTokens2.length, 1);

    await expect(stakingNftContract.stopStakingUnstakeAll())
      .to.emit(stakingNftContract, "Unstaked")
      .withArgs(account1Address, 0);

    const stakedTokens3 = await stakingNftContract.getStakedTokens(account1Address);
      assert.equal(stakedTokens3.length, 0);
    
    const stakedTokens4 = await stakingNftContract.getStakedTokens(account2Address);
      assert.equal(stakedTokens4.length, 0);
  })
})
