//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.0 <0.9.0;

contract Payout {
    address public marketplaceAccount;
    uint256 public marketplaceBalance;
    uint256 public totalActors = 0;
    uint256 public totalPayout = 0;
    uint256 public totalPayment = 0;

    mapping(address => bool) isActor;

    event Paid(
        uint256 id,
        address from,
        uint256 totalPayout,
        uint256 timestamp
    );

    struct PaymentStruct {
        uint256 id;
        address actor;
        uint256 progressPayment;
        uint256 timestamp;
    }

    PaymentStruct[] actors;

    modifier ownerOnly(){
        require(msg.sender == marketplaceAccount, "Owner reserved only");
        _;
    }

    constructor() {
        marketplaceAccount = msg.sender;
    }

    function addActor(
        address actor,
        uint256 progressPayment
    ) external ownerOnly returns (bool) {
        require(progressPayment > 0 ether, "Payment cannot be zero!");
        require(!isActor[actor], "Record already existing!");

        totalActors++;
        totalPayout += progressPayment;
        isActor[actor] = true;

        actors.push(
            PaymentStruct(
                totalActors,
                actor,
                progressPayment,
                block.timestamp
            )
        );
        
        return true;
    }

    function payActors() payable external ownerOnly returns (bool) {
        require(msg.value >= totalPayout, "Ethers too small");
        require(totalPayout <= marketplaceBalance, "Insufficient balance");

        for(uint i = 0; i < actors.length; i++) {
            payTo(actors[i].actor, actors[i].progressPayment);
        }

        totalPayment++;
        marketplaceBalance -= msg.value;

        emit Paid(
            totalPayment,
            marketplaceAccount,
            totalPayout,
            block.timestamp
        );

        return true;
    }

    function getActors() external view returns (PaymentStruct[] memory) {
        return actors;
    }

    function payTo(
        address to, 
        uint256 amount
    ) internal returns (bool) {
        (bool success,) = payable(to).call{value: amount}("");
        require(success, "Payment failed");
        return true;
    }
}