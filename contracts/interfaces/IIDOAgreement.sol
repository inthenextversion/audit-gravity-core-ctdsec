// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IIDOAgreement {
    
    struct DeFiCreationInfo{
        uint percentOfSale; /** @dev percent of sale that is used to provide liquidity for the swap pair */
        address otherAsset; /** @dev the other asset in the new swap pair */
        uint farmAllocation; /** @dev amount of IDO token to allocate to corresponding lp farm */
        bool created; /** bool used to track if corresponding defi assets were created, not used in agreement should be false */
        address lpToken; /** once swap pair has been made, the lp token address will be saved here */
    }

    function initialize(address _owner, address IDOImplementation) external;

    function locked() external view returns (bool);
    function owner() external view returns (address);
    function defi(uint i) external view returns(DeFiCreationInfo memory);
    function IDOname() external view returns(string memory);
    function IDOsymbol() external view returns(string memory);
    function package() external view returns(uint);
    function IDOImplementation() external view returns(address);
    function IDOToken() external view returns (address);
    function saleToken() external view returns (address);
    function price()external view returns(uint);
    function totalAmount()external view returns(uint);
    function saleStart()external view returns(uint);
    function saleEnd()external view returns(uint);
    function commission()external view returns(uint);
    function GFIcommission() external view returns(address);
    function treasury() external view returns(address);
    function reserves() external view returns(address);
    function GFISudoUser() external view returns(address);
    function clientSudoUser() external view returns(address);
    function timelock() external view returns(uint);
    function gracePeriod() external view returns(uint);
    function tierBuyLimits(uint i) external view returns(uint);
    function tierAmounts(uint i) external view returns(uint);
}