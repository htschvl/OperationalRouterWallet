pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20Receiver.sol";

contract TestWalletTransfer is AccessControl, IERC20Receiver {
    using SafeERC20 for IERC20;

    address private _hardcodedWithdrawalAddress;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant ACCOUNTANT_ROLE = keccak256("ACCOUNTANT_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");

    constructor(address hardcodedWithdrawalAddress) {
        require(hardcodedWithdrawalAddress != address(0), "");
        _hardcodedWithdrawalAddress = hardcodedWithdrawalAddress;
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    ///MODIFIERS///

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "");
        _;
    }

    modifier onlyAccountant() {
        require(hasRole(ACCOUNTANT_ROLE, msg.sender), "");
        _;
    }

    modifier onlyApprover() {
        require(hasRole(APPROVER_ROLE, msg.sender), "");
        _;
    }

    ///GRANT ROLES///

    function grantAccountantRole(address user) external onlyAdmin {
        grantRole(ACCOUNTANT_ROLE, user);
    }

    function grantApproverRole(address user) external onlyAdmin {
        grantRole(APPROVER_ROLE, user);
    }

    ///DEPOSIT///

    function depositNative() external payable {
        require(msg.value > 0, "");
    }

    function depositToken(address tokenAddress, uint256 amount) external {
        require(tokenAddress != address(0), "");
        require(amount > 0, "");

        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    ///WITHDRAW///

    function withdrawNative(uint256 amount) external onlyApprover {
        require(amount > 0, "");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "");
        require(contractBalance >= amount, "");

        (bool success, ) = payable(_hardcodedWithdrawalAddress).call{ value: amount }("");
        require(success, "");
    }

    function withdrawToken(address tokenAddress, uint256 amount) external onlyApprover {
        require(tokenAddress != address(0), "");
        require(amount > 0, "");

        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "");
        require(tokenBalance >= amount, "");

        token.safeTransfer(_hardcodedWithdrawalAddress, amount);
    }

    ///GET BALANCE///

    function getNativeBalance() external view onlyAccountant returns (uint256) {
        return address(this).balance;
    }

    function getERC20Balance(address tokenAddress) external view onlyAccountant returns (uint256) {
        require(tokenAddress != address(0), "");

        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

    function onERC20Received(address, address, uint256, bytes memory) external override returns (bytes4) {
        return this.onERC20Received.selector;
    }
}
