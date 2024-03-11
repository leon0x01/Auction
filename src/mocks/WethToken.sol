// SPDX-LIcense-Identfier: MIT
pragma solidity ^0.8.24;
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract WethToken is ERC20("ERC20MocK", "MCK") {
    function mint(address user, uint256 amount) public {
        // caller authroization need to set
        _mint(user, amount);
    }

    function burn(address user, uint256 amount) public {
        // caller authorization need to set
        _burn(user, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        return super.transfer(recipient, amount);
    }
}
