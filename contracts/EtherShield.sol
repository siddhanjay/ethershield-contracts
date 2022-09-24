// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract EtherShield is AccessControl {
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    mapping (address => bool) public keepers;
    mapping (address => address) public users; // origin address => destination address

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    event KeeperChanged(address indexed keeper, bool state);
    event UserChanged(address indexed user, address destination);
    event Rescue(address indexed user, address[] erc20Tokens);

    function addUser(address destination) external {
        require(destination != address(0), "AddUser:: Invalid address");
        users[msg.sender] = destination;
        emit UserChanged(msg.sender, destination);
    }

    function disableUser() external {
        users[msg.sender] = address(0);
        emit UserChanged(msg.sender, address(0));
    }

    function rescue(address _user, address[] calldata _erc20Tokens) external onlyRole(KEEPER_ROLE) {
        require(_user != address(0) ,"Rescue:: Invalid _user address");
        require(users[_user] != address(0) ,"Rescue:: User not registered");
        uint256 tokenLength = _erc20Tokens.length;
        for(uint i = 0 ;i < tokenLength; i++) {
            uint256 userBalance = IERC20(_erc20Tokens[i]).balanceOf(_user);
            if(userBalance > 0) {
                TransferHelper.safeTransferFrom(_erc20Tokens[i], _user, users[_user], userBalance);
            }
        }
        emit Rescue(_user, _erc20Tokens);
    }

}