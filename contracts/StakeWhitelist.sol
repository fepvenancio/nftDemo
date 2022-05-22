// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author filipeVenancio  
/// @title StakeWhitelist - a contract to manage a whitelist
/// @notice this will be used to stake the NFT. Only people on whitelist will be able to stake.
/// @dev still under development
contract StakeWhitelist {
    event Whitelisted(address member);
    mapping (address => bool) whitelist;

    /// @notice isOnWhitelist verifies if a given address is whitelisted
    /// @param _whitelisted the address that will be verified if it's whitelisted
    /// @return whitelist a boolean variable expressing if the address is whitelisted or not 
    function isOnWhitelist(address _whitelisted) public view returns(bool) {
        return whitelist[_whitelisted];
    }

    /// @notice addOnWhitelist addes the member address to a mapping - Whitelist
    /// @param _member the address that will be whitelisted
    /// it confirms if the address is whitelisted and emits an event with
    /// the members address.
    function addOnWhitelist(address _member) public {
        require(!isOnWhitelist(_member), "Address is already a member.");
        whitelist[_member] = true;
        emit Whitelisted(_member);
    }
}