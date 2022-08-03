//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Factory.sol";

abstract contract MarketPlace is Factory {
    using Counters for Counters.Counter;
    //keep track of all token ids
    Counters.Counter private _itemIds;
    //keeps track of all sold tokenIDs
    Counters.Counter private _itemsSold;

    address payable owner;
    //listing price
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //mapping each marketItem to an Id
    mapping(uint256 => MarketItem) private idToMarketItem;

    //event to be emitted when a marketId is created
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold
    );

    /**
    @notice reterns the listing price 
     */
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /**
     @notice create a marketItem to be up for sale
     @param nftContract contract address of the nft that wants to be created
     @param tokenId Id of the token to be created- returend at the point of minting the contract
     @param price price of the item to be created
     */
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "price must be at least 1 wei");
        require(
            msg.value == listingPrice,
            "price must be equal to the listing price"
        );

        _itemIds.increment();
        uint256 newItemId = _itemIds.current();

        idToMarketItem[newItemId] = MarketItem(
            newItemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            newItemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
    }

    /**
     @notice create a marketsale
     @param nftContract contract address of the nft that wants to be created
     @param itemId Id of the item to be put on sale-
    
     */
    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;

        require(
            msg.value == price,
            "please submit asking price inorder to complete the purchase"
        );
        idToMarketItem[itemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        _itemsSold.increment();
        payable(owner).transfer(listingPrice);
    }

    /**
     @notice fetch totalmarket items created
    
     */
    function fetchMarketitems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unSoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /**
     @notice fetch all Ntfs purchased my current user
    
     */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    /**
     @notice fetch all Ntfs created my current user
    
     */
    function fetchItemsCreated() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _itemIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = idToMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /**
     @notice provide collateral to Factory contract
     @param amount amount of collateral users wants to suply
     */

    function supplyCollateral(uint256 amount) public {
        payable(factoryAddress).transfer(amount);
        this.mintAssetsToCompound(msg.sender, amount);
    }

    /**
     @notice borrow Asset from Factory contract
     @param amount amount of asset users wants to borrow
     */
    function borrowAsset(uint256 amount) public {
        this.borrowAssetFromCompound(msg.sender, amount);
    }

    /**
     @notice repay borrowed Asset from Factory contract
     @param amount amount of asset users wants to repay
     */
    function repayBorrowed(uint256 amount) public {
        payable(factoryAddress).transfer(amount);
        this.repayBorrowedAsset(msg.sender, amount);
    }
}
