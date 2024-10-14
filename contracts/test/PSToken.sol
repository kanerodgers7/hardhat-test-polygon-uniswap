// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/src/tokens/ERC20.sol";

contract PSToken is ERC20 {
    uint256 public feeNominator = 1; // Default fee percentage (0.1%)
    uint256 public feeDenominator = 1000; // Default fee percentage (0.1%)
    address public feeAddress;
    uint256 public accumulatedFees;

    error MintableError(address from, uint256 balance, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        address _feeAddress,
        uint8 decimals_
    ) ERC20(name, symbol, decimals_) {
        feeAddress = _feeAddress;
    }

    // Override the decimals function to return the custom value

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        // revert MintableError(from, balanceOf[from], amount);
        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 feeAmount = (amount * feeNominator) / feeDenominator;
        uint256 amountAfterFee = amount - feeAmount;
        _transfer(msg.sender, to, amountAfterFee);
        if (feeAmount > 0) {
            _transfer(msg.sender, address(this), feeAmount);
            accumulatedFees += feeAmount; // Accumulate the fee in the contract
        }
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        return super.approve(spender, amount);
    }

    function _approve(
        address from,
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        allowance[from][spender] = amount;

        emit Approval(from, spender, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 feeAmount = (amount * feeNominator) / feeDenominator;
        uint256 amountAfterFee = amount - feeAmount;
        _transfer(from, to, amountAfterFee);

        if (feeAmount > 0) {
            accumulatedFees += feeAmount; // Accumulate the fee in the contract
            _transfer(from, address(this), feeAmount);
        }
        _approve(from, msg.sender, allowance[from][msg.sender] - amount);
        return true;
    }

    function setFeeAddress(address _feeAddress) public {
        feeAddress = _feeAddress;
    }

    function setFeeFactor(uint256 _nominator, uint256 _denominator) public {
        feeNominator = _nominator;
        feeDenominator = _denominator;
    }

    function harvestFees() public {
        require(accumulatedFees > 0, "No fees to harvest");
        _transfer(address(this), feeAddress, accumulatedFees);
        accumulatedFees = 0;
    }

    function transferFee(uint256 _amount) public view returns (uint256) {
        return _amount / (feeDenominator - feeNominator);
    }

    function isPst() public pure returns (bool) {
        return true;
    }
}
