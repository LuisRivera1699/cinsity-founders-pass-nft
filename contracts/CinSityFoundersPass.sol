//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CinSityFoundersPass is ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    // Sale status
    enum SaleStatus {
        Wave1,
        Wave2,
        Wave3,
        Soldout,
        Reveal
    }

    SaleStatus public saleStatus;

    // Minting restriction variables
    uint256 MAX_MINT_AT_ONCE = 10;
    uint256 WAVE_1_MAX_TOKENS = 1000;
    uint256 WAVE_2_MAX_TOKENS = 3750;
    uint256 WAVE_3_MAX_TOKENS = 7300;
    uint256 WAVE_3_TEAM_MAX_TOKENS = 7500;

    uint256 WAVE_2_PUBLIC_PRICE = 12 * 10**17;
    uint256 WAVE_2_WHITELIST_PRICE = 91 * 10**16;

    uint256 WAVE_3_PRICE = 15 * 10**17;

    bool isPaused = false;

    mapping(address => bool) public wave2WhitelistWallets;
    mapping(address => bool) public teamsLast200Wallets;

    constructor() ERC721("CinSity DAO Founders Pass", "CSDAO") {
        saleStatus = SaleStatus.Wave1;
    }

    // Wave 1
    function mintWave1FoundersPassForHolders(address[] memory holders)
        external
        onlyOwner
    {
        require(saleStatus == SaleStatus.Wave1, "Wave 1 has already passed.");
        require(
            _tokenId.current() + holders.length <= WAVE_1_MAX_TOKENS,
            "This would exceed the quantity of minted tokens in Wave 1."
        );

        for (uint256 i = 0; i < holders.length; i++) {
            _safeMint(holders[i], _tokenId.current());

            _tokenId.increment();
        }
    }

    function startWave2() external onlyOwner {
        require(
            saleStatus == SaleStatus.Wave1,
            "Wave 2 can only start after Wave 1."
        );
        require(
            _tokenId.current() == WAVE_1_MAX_TOKENS,
            "Wave 2 can't start if Wave 1 tokens amount has not been reached."
        );

        saleStatus = SaleStatus.Wave2;
    }

    // Wave 2
    function addAddressesToWave2Whitelist(address[] memory whitelisted)
        external
        onlyOwner
    {
        require(
            saleStatus == SaleStatus.Wave2 || saleStatus == SaleStatus.Wave1,
            "Wave 2 Whitelist can only be updated before Wave 2 has finished."
        );
        for (uint256 i = 0; i < whitelisted.length; i++) {
            wave2WhitelistWallets[whitelisted[i]] = true;
        }
    }

    function _mintWave2FoundersPass(uint256 quantity) internal {
        require(
            _tokenId.current() < WAVE_2_MAX_TOKENS,
            "Wave 2 already sold out."
        );
        require(
            _tokenId.current() + quantity <= WAVE_2_MAX_TOKENS,
            "This mint would exceed the max quantity of tokens for Wave 2."
        );

        if (wave2WhitelistWallets[msg.sender]) {
            require(
                msg.value == WAVE_2_WHITELIST_PRICE * quantity,
                "No sufficient funds."
            );
        } else {
            require(
                msg.value == WAVE_2_PUBLIC_PRICE * quantity,
                "No sufficient funds."
            );
        }

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenId.current());

            _tokenId.increment();

            if (_tokenId.current() == WAVE_2_MAX_TOKENS) {
                _startWave3();
            }
        }
    }

    function _startWave3() internal {
        require(
            saleStatus == SaleStatus.Wave2,
            "Wave 3 can only start after Wave 2."
        );

        saleStatus = SaleStatus.Wave3;
    }

    // Wave 3
    function _mintWave3FoundersPass(uint256 quantity) internal {
        require(
            _tokenId.current() < WAVE_3_MAX_TOKENS,
            "Wave 3 already sold out."
        );
        require(
            _tokenId.current() + quantity <= WAVE_3_MAX_TOKENS,
            "This mint would exceed the max quantity of tokens for Wave 3."
        );

        require(msg.value == WAVE_3_PRICE * quantity, "No sufficient funds.");

        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenId.current());

            _tokenId.increment();

            if (_tokenId.current() == WAVE_3_MAX_TOKENS) {
                saleStatus = SaleStatus.Soldout;
            }
        }
    }

    // Mint
    function mintFoundersPass(uint256 quantity) external payable {
        require(!isPaused, "Sale is paused, come back later.");
        require(
            saleStatus == SaleStatus.Wave2 || saleStatus == SaleStatus.Wave3,
            "You can only mint if Wave 2 or Wave 3 is active."
        );
        require(
            quantity > 0,
            "Come on man, you have to mint at least 1 pass. Don't waste gas fees."
        );
        require(
            quantity <= MAX_MINT_AT_ONCE,
            "You can only mint 10 passes at once."
        );

        if (saleStatus == SaleStatus.Wave2) {
            _mintWave2FoundersPass(quantity);
        } else if (saleStatus == SaleStatus.Wave3) {
            _mintWave3FoundersPass(quantity);
        }
    }
}
