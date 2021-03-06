// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract RegistrationContract { 

    event Registered(address _registeredUser);

    function register() external {
        emit Registered(msg.sender);
    }
}