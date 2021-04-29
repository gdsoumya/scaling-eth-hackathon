
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.4;

import "./L2DepositedERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "hardhat/console.sol";
/* Library Imports */
import { OVM_CrossDomainEnabled } from "@eth-optimism/contracts/libraries/bridge/OVM_CrossDomainEnabled.sol";

contract L2_Pool is ERC20, Ownable, OVM_CrossDomainEnabled {

  using SafeMath for uint256;

  L2DepositedERC20 public L2_dai;
  address public L1_Pool;


  event Deposit(address from, uint256 deposit, uint256 poolTokens);
  event Withdrawal(address to, uint256 amount);

  constructor(
    L2DepositedERC20 dai_,
    address L1Pool,
    address _l2CrossDomainMessenger
  ) OVM_CrossDomainEnabled(_l2CrossDomainMessenger)
    ERC20(100000, "Popcorn DAI L1_Pool")  {
    L2_dai = dai_;
    L1_Pool = L1Pool;
  }

  function deposit(uint256 amount) external returns (uint256) {
    require(L2_dai.balanceOf(msg.sender) >= amount, "not enough DAI");

    uint256 poolTokens = _issuePoolTokens(msg.sender, amount);
    emit Deposit(msg.sender, amount, poolTokens);

    L2_dai.withdrawTo(L1_Pool, amount);

    return this.balanceOf(msg.sender);
  }

  function withdraw(uint256 amount) external returns (uint256 withdrawalAmount) {
    // check if timelock has expired

    require(amount <= this.balanceOf(msg.sender));
    _burnPoolTokens(msg.sender, amount);

    sendCrossDomainMessage(L1_Pool,
      abi.encodeWithSignature(
        "withdraw(unit256,address)",
        amount,
        msg.sender
        ),
        1000000
    );
  }

  function _burnPoolTokens(address from, uint256 amount) internal returns (uint256 burnedAmount) {
    _burn(from, amount);
    return amount;
  }

  function _issuePoolTokens(address to, uint256 amount) internal returns (uint256 issuedAmount) {
    _mint(to, amount);
    return amount;
  }
}
