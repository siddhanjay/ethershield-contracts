// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract EtherShield is AccessControl {
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    mapping (address => bool) public keepers;
    mapping (address => address) public users; // origin address => destination address
    uint256 public transferFeePercent;
    uint256 public registrationFee;
    address public feeRecipient;

    constructor(address _feeRecipient) {
        require(_feeRecipient != address(0), "0 address");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        transferFeePercent = 5;
        feeRecipient = _feeRecipient;
        registrationFee = 0.1 ether;
    }

    event KeeperChanged(address indexed keeper, bool state);
    event UserChanged(address indexed user, address destination);
    event Rescue(address indexed user, address[] erc20Tokens);

    function addUser(address destination) external {
        require(destination != address(0), "AddUser:: Invalid address");
        require(msg.value >= registrationFee, "AddUser:: Not enough fee");
        users[msg.sender] = destination;
        emit UserChanged(msg.sender, destination);
    }

    function setTransferFeePercent(uint256 _transferFeePercent) external onlyRole(DEFAULT_ADMIN_ROLE) {
        transferFeePercent = _transferFeePercent;
    }

    function setRegistrationFee(uint256 _registrationFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        registrationFee = _registrationFee;
    }

    function disableUser() external {
        users[msg.sender] = address(0);
        emit UserChanged(msg.sender, address(0));
    }

    function withdrawFees(address _to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_to != address(0), "WithdrawFees:: Invalid address");
        TransferHelper.safeTransferETH(_to, address(this).balance);
    }

    function rescue(address _user, address[] calldata _erc20Tokens) external onlyRole(KEEPER_ROLE) {
        require(_user != address(0) ,"Rescue:: Invalid _user address");
        require(users[_user] != address(0) ,"Rescue:: User not registered");
        uint256 tokenLength = _erc20Tokens.length;
        for(uint i = 0 ;i < tokenLength; i++) {
            uint256 userBalance = IERC20(_erc20Tokens[i]).balanceOf(_user);
            uint256 transferFeeAmount = (userBalance * transferFeePercent) / 100;
            uint256 userTransferAmount = userBalance - transferFeeAmount;
            if(userTransferAmount > 0) {
                TransferHelper.safeTransferFrom(_erc20Tokens[i], _user, users[_user], userTransferAmount);
                TransferHelper.safeTransferFrom(_erc20Tokens[i], _user, feeRecipient, transferFeeAmount);
            }
        }
        emit Rescue(_user, _erc20Tokens);
    }

}