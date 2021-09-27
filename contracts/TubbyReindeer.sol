// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import './ERC2981PerTokenRoyalties.sol';

contract TubbyReindeer is ERC721, ERC2981PerTokenRoyalties, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    mapping (uint => address) firstOwner;
    mapping (uint => address) previousOwner;
    
    uint256 hardCap = 5001;
    uint256 private tokenPrice = 2500000000000000000; // 2.5 Avax
    string public baseUri = "";
    bool salesIsOpen = false;
    bool metadataLocked = false;
    
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("TubbyReindeer", "TR") {
        _tokenIdCounter.increment();
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981PerTokenRoyalties) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || ERC2981PerTokenRoyalties.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }
    
    function toggleSales() public onlyOwner { 
        salesIsOpen = !salesIsOpen;
    }

    function safeMint(uint256 amountToMint) public payable {
        require(salesIsOpen == true, "Sales is not open");
        
        uint256 _currentToken = _tokenIdCounter.current();
        
        require(amountToMint < 21, "Can't mint too much at once!");
        require(_currentToken + amountToMint < hardCap, "Limit reached");
        require(msg.value == tokenPrice.mul(amountToMint), "That is not the right price!");
        
        
        require(_tokenIdCounter.current() < hardCap, "Hard cap reached");
        
        for(uint256 i = 0; i < amountToMint; i++){
            firstOwner[_tokenIdCounter.current()] = msg.sender;
            _setTokenRoyalty(_tokenIdCounter.current(), 0x4301480bE8D0C72311B32bd16CFC129714Fe52B5, 400);
			_safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
		}
    }
    
    function customBurn(uint256 tokenId) public {
	    require(ownerOf(tokenId) == msg.sender, "You don't own this Tubby!");
	    previousOwner[tokenId] = msg.sender;
	    _transfer(msg.sender, 0x000000000000000000000000000000000000dEaD, tokenId);
	}
	
	function getAmountMinted() public view returns(uint256) { 
	    return  _tokenIdCounter.current();
	}
	
	
	function getFirstOwner(uint256 tokenId) public view returns(address) {
	    return firstOwner[tokenId];
	}
	
	function getPreviousOwner(uint256 tokenId) public view returns(address) {
	    return previousOwner[tokenId];
	}
	
	function getPrice() public view returns(uint256) { 
	    return tokenPrice;
	}
	
	function setBaseUri(string memory newUri) public onlyOwner {
        require(metadataLocked == false, "Metadata are locked");
        baseUri = newUri;
    }
    
    function changePrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }
    
    function lockMetadata() public onlyOwner {
        require(metadataLocked == false, "Metadata are already locked");
        metadataLocked = true;
    }
    
	function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
