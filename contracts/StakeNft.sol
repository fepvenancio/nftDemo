// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "hardhat/console.sol";
import "../contracts/StakeWhitelist.sol";

contract StakingSystem is Ownable, ERC721Holder {
    IERC721 public nft;
    StakeWhitelist whitelist;

    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 constant stakingTime = 300 seconds; //Time for the demo
    
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingCoolDown;
        uint256 balance;
    }

    constructor(IERC721 _nft) Ownable() {
        nft = _nft;
    }

    mapping(address => Staker) public stakers;

    mapping(uint256 => address) public tokenOwner;
    bool public tokensClaimable;
    bool initialised;

    event Staked(address owner, uint256 amount);
    event Unstaked(address owner, uint256 amount);

    function initStaking() public onlyOwner {
        //needs access control
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    function getStakedTokens(address _user) public view returns (uint256[] memory tokenIds) {
        return stakers[_user].tokenIds;
    }

    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(initialised, "Staking System: the staking has not started");
        require(whitelist.isOnWhitelist(msg.sender), "must be a whitelisted member");
        require(nft.ownerOf(_tokenId) == _user, "member must be the owner of the token");
        Staker storage staker = stakers[_user];

        staker.tokenIds.push(_tokenId);
        staker.tokenStakingCoolDown[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = _user;
        nft.approve(address(this), _tokenId);
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstake(uint256 _tokenId) public {
        _unstake(msg.sender, _tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds) public onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == _user, "Nft Staking System: user must be the owner of the staked nft");
        Staker storage staker = stakers[_user];
        
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
        }
        
        staker.tokenStakingCoolDown[_tokenId] = 0;
        delete tokenOwner[_tokenId];

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }
}