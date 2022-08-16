// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract EtherShield is Ownable {

    mapping (address => bool) public keepers;
    mapping (address => address) public users; // origin address => destination address

    event KeeperChanged(address indexed keeper, bool state);
    event UserChanged(address indexed user, address destination);
    event Rescue(address indexed user, address[] erc20Tokens);

    function addKeepers(address _keeper) external onlyOwner {
        keepers[_keeper] = true;
        emit KeeperChanged(_keeper, true);
    }

    function removeKeeper(address _keeper) external onlyOwner {
        keepers[_keeper] = false;
        emit KeeperChanged(_keeper, false);
    }

    function addUser(address _destination) external {
        users[msg.sender] = _destination;
        emit UserChanged(msg.sender, _destination);
    }

    function disableUser() external {
        users[msg.sender] = address(0);
        emit UserChanged(msg.sender, address(0));
    }

    function rescue(address _user, address[] calldata _erc20Tokens) external onlyKeeper {
        address destination = users[_user];
        require(_user != address(0) ,'invalid _user address');
        require(destination != address(0) ,'user is not registered');
        uint256 tokenLength = _erc20Tokens.length;
        for(uint i = 0 ;i < tokenLength; i++) {
            ERC20 token = ERC20(_erc20Tokens[i]);
            uint256 userBalance = token.balanceOf(_user);
            if(userBalance > 0) {
                token.transferFrom(_user, destination, userBalance);
            }
        }
        emit Rescue(_user, _erc20Tokens);
    }

    modifier onlyKeeper {
        require(keepers[msg.sender],'not a keeper');
        _;
    }
}
