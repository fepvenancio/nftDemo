// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StakeWhitelist {
    event Whitelisted(address member);
    mapping (address => bool) whitelist;

    constructor() {
    }

    function isOnWhitelist(address _whitelisted) public view returns(bool) {
        return whitelist[_whitelisted];
    }

    function addOnWhitelist(address _member) public {
        require(!isOnWhitelist(_member), "Address is already a member.");
        whitelist[_member] = true;
        emit Whitelisted(_member);
    }
}