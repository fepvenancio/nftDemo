// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./StakeWhitelist.sol";

contract StakingSystem is ERC721Holder, Ownable {
    IERC721 public nft;
    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 constant stakingTime = 300 seconds; //Time for the demo
    bool initialised;
    address stakeWhitelist;
    
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingCoolDown;
        uint256 balance;
    }

    constructor(IERC721 _nft) {
        StakeWhitelist _stakeWhitelist = new StakeWhitelist();
        stakeWhitelist = address(_stakeWhitelist);
        nft = _nft;
        super;
    }

    mapping(address => Staker) public stakers;
    mapping(uint256 => address) public tokenOwner;

    event Staked(address owner, uint256 amount);
    event Unstaked(address owner, uint256 amount);

    function initStaking() public onlyOwner {
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

    function addOnWhitelist(address _member) public onlyOwner {
        StakeWhitelist _stakeWhitelist = StakeWhitelist(stakeWhitelist);
        _stakeWhitelist.addOnWhitelist(_member);
    }

    function isOnWhitelist(address _member) public view returns(bool) {
        StakeWhitelist _stakeWhitelist = StakeWhitelist(stakeWhitelist);
        return _stakeWhitelist.isOnWhitelist(_member);
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(initialised, "Staking System: the staking has not started");
        require(isOnWhitelist(_user), "member must be on the whitelist");
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
        require(tokenOwner[_tokenId] == _user, "member must be the owner of the staked nft");
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