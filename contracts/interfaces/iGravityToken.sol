// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface iGravityToken is IERC20 {

    function setGovernanceAddress(address _address) external;

    function changeGovernanceForwarding(bool _bool) external;

    function burn(uint256 _amount) external returns (bool);
}