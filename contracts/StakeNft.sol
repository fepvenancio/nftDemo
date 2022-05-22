// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./StakeWhitelist.sol";
import "hardhat/console.sol";

/// @title StakingSystem A Staking contract where the NFTs will be staked
/// @author filipeVenancio  
contract StakingSystem is ERC721Holder, Ownable {
    IERC721 public nft;
    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 constant stakingTime = 300 seconds; //Time for the demo
    address[] public arrGetUsersAddress;

    bool initialised;
    address stakeWhitelist;
    
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingCoolDown;
        uint256 balance;
    }

    /// @notice The constructor will be the 1st thing executing on the contract
    /// it will take a ERC721 token and will generate the Whitelist contract
    /// @param _nft an ERC721 interface - MoonNFT Contract. 
    constructor(IERC721 _nft) {
        StakeWhitelist _stakeWhitelist = new StakeWhitelist();
        stakeWhitelist = address(_stakeWhitelist);
        nft = _nft;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenOwner;

    event Staked(address owner, uint256 amount);
    event Unstaked(address owner, uint256 amount);

    /// @notice addOnWhitelist this function accesses the StakeWhitelist contract and add to the whitelist
    /// @param _member is takes an address as the member to add and can only be executed by the owner
    function addOnWhitelist(address _member) public onlyOwner {
        StakeWhitelist _stakeWhitelist = StakeWhitelist(stakeWhitelist);
        _stakeWhitelist.addOnWhitelist(_member);
    }

    /// @notice isOnWhitelist will verify if the member is whitelisted (can access the staking pool)
    /// @param _member an address to be verified if it is a member
    /// @return boolean value, true or false if the address is whitelisted.
    function isOnWhitelist(address _member) public view returns(bool) {
        StakeWhitelist _stakeWhitelist = StakeWhitelist(stakeWhitelist);
        return _stakeWhitelist.isOnWhitelist(_member);
    }

    /// @notice initStaking initializes the staking, it verifies if it is already initialised
    /// stores a dateTime variable and a bool to validate if initialised or not.
    function initStaking() public onlyOwner {
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    /// @notice getStakedTokens returns the staked NFTs of a given address
    /// @param _user the address to be verified if is staking or not and if so which tokenIds
    /// @return tokenIds an array of the tokens staked by a given address.
    function getStakedTokens(address _user) public view returns (uint256[] memory tokenIds) {
        return stakers[_user].tokenIds;
    }

    /// @notice stake calls the internal staking function.
    /// @param tokenId the Id of the NFT to be staked by the message sender
    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    /// @notice _stake the internal function that will stake the NFT
    /// requires the staking pool to be initialised, whitelisted and if the user is the owner of the NFT
    /// @param _user address that will be staking the token (NFT)
    /// @param _tokenId the Id of the NFT that will be staked
    function _stake(address _user, uint256 _tokenId) internal {
        require(initialised, "Staking System: the staking has not started");
        require(isOnWhitelist(_user), "member must be on the whitelist");
        require(nft.ownerOf(_tokenId) == _user, "member must be the owner of the token");
        arrGetUsersAddress.push(_user);
        Staker storage staker = stakers[_user];
        staker.tokenIds.push(_tokenId);
        staker.tokenStakingCoolDown[_tokenId] = block.timestamp;
        staker.balance += 1;
        tokenOwner[_tokenId] = _user;
        nft.approve(address(this), _tokenId);
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    /// @notice stopStaking it will stop the staking pool - if Initialised is false
    /// the members won't be allow to stake.
    function stopStaking() public onlyOwner {
        require(initialised, "Not initialized");
        initialised = false;
    }

    /// @notice stopStakingUnstake it will call two functions, one to stop the staking and 
    /// other that will unstake a given address and tokenID. 
    /// Requires the staking pool to be initialised
    /// @param _user the users address to unstake
    /// @param _tokenId the NFT id to be unstaked
    function stopStakingUnstake(address _user, uint256 _tokenId) public onlyOwner {
        require(initialised, "staking needs to be initialized");
        stopStaking();
        _unstake(_user, _tokenId);
    }

    /// @notice stopStakingUnstakeAll it will call 2 functions, one to stop staking and
    /// other that will unstake all the Staked NFTs from the pool
    /// Requires the staking pool to be initialised
    function stopStakingUnstakeAll() public onlyOwner {
        require(initialised, "staking needs to be initialized");
        stopStaking();
        unstakeAll();
    }

    /// @notice unstake - call the internal function to unstake the tokens (NFTs)
    /// @param _tokenId the Id of the staked NFT and the address of the message sender.
    function unstake(uint256 _tokenId) public {
        _unstake(msg.sender, _tokenId);
    }

    /// @notice unstakeAll - A function that only the Owner can run, it will unstake
    /// all the staked tokens (NFTs) and return them to their owners.
    /// it uses an array that saves/deletes addresses while they are stake/unstake
    function unstakeAll() public onlyOwner {
        for(uint256 i = 0; i < arrGetUsersAddress.length; i++) {
            uint256[] memory _tokenIds = getStakedTokens(arrGetUsersAddress[i]);
            uint256 tokenIdsLength = _tokenIds.length;
            for(uint256 j = 0; j < tokenIdsLength; j++) {
                _unstake(arrGetUsersAddress[i], _tokenIds[j]);
            }
        }
    }

    /// @notice unstakeBatch - Will unstake more than one NFT of the same owner
    /// @param tokenIds an array of the existing tokens on the message sender address
    function unstakeBatch(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }

    /// @notice _unstake an internal function to unstake the tokens (NFT)
    /// it will verify if the _user is the owner of the NFT
    /// @param _user the address owner of the NFT
    /// @param _tokenId the Id of the NFT
    function _unstake(address _user, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == _user, "member must be the owner of the staked nft");
        Staker storage staker = stakers[_user];
        
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
        }

        staker.tokenStakingCoolDown[_tokenId] = 0;
        staker.balance -= 1;
        delete tokenOwner[_tokenId];
        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }
}