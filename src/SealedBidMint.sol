// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract SealedBidMint is ERC721 {
    struct SealedBid {
        uint256 ethAttached;
        bytes32 commitHash;
    }
    error EZeroHash();
    error EAlreadyExistedBid();
    error EZeroAmount();
    error EBiddingStillOn();
    error ENotABidder();
    error EInvalidCommitHash();
    error EWinnerCannotClaim();

    event AuctionStarted(uint256 launchTime, uint256 auctionId);

    event AuctionSettled(address indexed winner);

    event BidSubmitted(address indexed bidder, uint256 amount);

    uint256 public constant AUCTION_COMMIT_DURATION = 30 minutes;
    uint256 public constant AUCTION_REVEAL_DURATION = 60 minutes;
    uint256 public constant AUCTION_TOTAL_DURATION = 60 minutes;

    uint256 public LAUNCH_TIME;
    uint256 public lastTokenId;
    uint256 public currentAuctionId;
    mapping(uint256 auctionId => mapping(address sender => SealedBid))
        public bidsByAuction;
    mapping(uint256 auctionId => address winner) public winningBidderByAuction;
    mapping(uint256 auctionId => uint256 amount)
        public winningBidAmountByAuction;

    // need to handled where startAuction only called by the auctioner
    // set auction id

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function startAuction() external {
        LAUNCH_TIME = block.timestamp;
        currentAuctionId = getCurrentAuctionId();

        emit AuctionStarted(LAUNCH_TIME, currentAuctionId);
    }
    // keccak256 hash (bidAmount + salt) and bidAmount and salt are only
    // known to the bidder
    function bid(uint256 auctionId, bytes32 commitHash) external payable {
        if (commitHash == 0) revert EZeroHash();
        if (bidsByAuction[auctionId][msg.sender].commitHash == commitHash)
            revert EAlreadyExistedBid();
        if (msg.value != 0) revert EZeroAmount();
        bidsByAuction[auctionId][msg.sender] = SealedBid({
            ethAttached: msg.value,
            commitHash: commitHash
        });
    }

    // Reveal a previously placed sealed bit

    function revealSealedBid(
        uint256 auctionId,
        uint256 bidAmount,
        bytes32 salt
    ) external {
        //  if (block.timstamp < AUCTION_TOTAL_DURATION) revert EBiddingStillOn();
        if (bidsByAuction[auctionId][msg.sender].commitHash == 0)
            revert ENotABidder();
        SealedBid memory $bid = bidsByAuction[auctionId][msg.sender];
        // ensure the bidAmount and salt is match with the bidded comithash
        if ($bid.commitHash != keccak256(abi.encode(bidAmount, salt)))
            revert EInvalidCommitHash();
        uint256 cappedBidAmount = bidAmount > $bid.ethAttached
            ? $bid.ethAttached
            : bidAmount;
        uint256 winningBidAmount = winningBidAmountByAuction[auctionId];
        if (cappedBidAmount > winningBidAmount) {
            winningBidderByAuction[auctionId] = msg.sender;
            winningBidAmountByAuction[auctionId] = cappedBidAmount;
        }
    }

    // Refund Eth attached to a losing (or unrevealed) bid
    // this can only be called afte  the bidding phase of an auction has ended.
    function reclaim(uint256 auctionId) external {
        //  require(block.timestamp > AUCTION_TOTAL_DURATION, EBiddingStillOn());
        address winningBidder = winningBidderByAuction[auctionId];
        if (winningBidder == msg.sender) revert EWinnerCannotClaim();
        SealedBid storage $bid = bidsByAuction[auctionId][msg.sender];
        uint256 refund = $bid.ethAttached;
        if (refund == 0) revert EZeroAmount();
        SafeTransferLib.safeTransferETH(msg.sender, refund);
    }

    // need to called only by the auctioneer who held the auction
    function mint(uint256 auctionId) external {
        //   require(block.timestamp > AUCTION_TOTAL_DURATION, EBiddingStillOn());
        address winningBidder = winningBidderByAuction[auctionId];
        SealedBid storage $bid = bidsByAuction[auctionId][winningBidder];
        uint256 ethAttached = $bid.ethAttached;
        if (ethAttached == 0) revert EZeroAmount();
        SafeTransferLib.safeTransferETH(msg.sender, ethAttached);
        uint256 newItemId = ++lastTokenId;
        _safeMint(winningBidder, newItemId);
        lastTokenId = newItemId;
    }

    function getCurrentAuctionId() public view returns (uint256 auctionId) {
        return (block.timestamp - LAUNCH_TIME) / AUCTION_COMMIT_DURATION + 1;
    }
    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        return Strings.toString(id);
    }
}
