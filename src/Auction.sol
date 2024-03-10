// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract Auction {
    // error throws when trying to submit a bid lower than
    error NotEnoughETH();

    // errows throws when trying to submit a bid after the auction's end
    error AuctionEnded();

    // errors throws when trying to settle the auction while it's still going
    error AuctionNotEnded();

    // Events

    event AuctionStarted(uint256 endTime);

    event AuctionSettled(address indexed winner);

    event BidSubmitted(address indexed bidder, uint256 amount);

    // bider and their amount
    struct Bid {
        address bidder;
        uint256 amount;
    }
    // need to initialized in constructor for dynamic prize
    // for now just for checking value are assinged static
    uint256 public constant AUCTION_PRIZE = 1 ether;

    uint256 public constant AUCTION_DURATION = 24 hours;

    uint256 public constant BID_INCREMENT = 0.05 ether;

    address public immutable manager = msg.sender;

    Bid public highestBid;

    Bid public secondBid;

    uint256 public endTime;

    // logic

    function start() public payable {
        if (address(this).balance < AUCTION_PRIZE) {
            revert NotEnoughETH();
        }
        // current start time + duration
        endTime = block.timestamp + AUCTION_DURATION;

        emit AuctionStarted(endTime);
    }

    // 1. users come and bid
    // 2. duration checks
    // 3. must be greater than highestBid
    // 4. if new highestbid is greater than previous one
    // 5. need to refund the previous bid to previous bidder

    function bid() public payable {
        if (block.timestamp > endTime) revert AuctionEnded();
        // if you want to bid always need to bid higher than previous
        // one
        if (msg.value < highestBid.amount + BID_INCREMENT)
            revert NotEnoughETH();
        Bid memory refund = secondBid;
        secondBid = highestBid;
        // need to track the secondBid to select highest bidder from
        // all bidder at once after endTime
        // Now in this case if hih
        highestBid = Bid({bidder: msg.sender, amount: msg.value});
        emit BidSubmitted(msg.sender, msg.value);

        SafeTransferLib.safeTransferETH(refund.bidder, refund.amount);
    }

    function settle() public payable {
        if (block.timestamp <= endTime) revert AuctionNotEnded();
        emit AuctionSettled(highestBid.bidder);
        SafeTransferLib.safeTransferETH(highestBid.bidder, AUCTION_PRIZE);
        SafeTransferLib.safeTransferETH(manager, address(this).balance);
    }
}
