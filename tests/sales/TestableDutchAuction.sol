// SPDX-License-Identifier: MIT
// Copyright (c) 2021 Divergent Technologies Ltd (github.com/divergencetech)
pragma solidity >=0.8.0 <0.9.0;

import "../../contracts/sales/LinearDutchAuction.sol";

/**
@notice Exposes a buy() function to allow testing of DutchAuction and, by proxy,
Seller.
@dev Setting the price decrease of the DutchAuction to zero is identical to a
constant Seller. Creating only a single Testable contract is simpler.
 */
contract TestableDutchAuction is LinearDutchAuction {
    constructor(
        LinearDutchAuction.DutchAuctionConfig memory auctionConfig,
        Seller.SellerConfig memory sellerConfig,
        address payable beneficiary
    ) LinearDutchAuction(auctionConfig, sellerConfig, beneficiary) {}

    uint256 private total;
    mapping(address => uint256) public purchased;

    /**
    @dev Override of Seller._handlePurchase(), called by Seller._purchase()
    after enforcing any caps, iff n > 0. This is where the primary logic of a
    sale is handled, e.g. ERC721 minting.
     */
    function _handlePurchase(uint256 n) internal override {
        total += n;
        purchased[tx.origin] += n;
    }

    /**
    @dev Override of Seller.totalSupply(). Usually this would be
    fulfilled by ERC721Enumerable.
     */
    function totalSupply() public view override returns (uint256) {
        return total;
    }

    /// @dev Public API for testing of _purchase().
    function buy(uint256 n) public payable {
        Seller._purchase(n);
    }
}

/// @notice Buys on behalf of a sender to circumvent per-address limits.
contract ProxyPurchaser {
    TestableDutchAuction public auction;

    constructor(address _auction) {
        auction = TestableDutchAuction(_auction);
    }

    function buy(uint256 n) public payable {
        auction.buy(n);
    }
}