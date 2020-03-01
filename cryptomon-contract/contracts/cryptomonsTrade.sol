pragma solidity ^0.5.11;

import "./cryptomonsFight.sol";

contract CryptomonsTrade is CryptomonsFight{

    // Only the owner can change the trade status, and decide the trade price
    function sellCryptomon(uint id, uint price) public onlyOwnerOf(id) {       
        require(
            id < totalCryptomons,
            "Id out of range"
        );
        require(
            getCoolDownStatus(id),
            "Not Ready For Sale"
        );
        cryptomons[id].price = price;
        cryptomons[id].forSale = true;
    }

    // Only the owner can retreive the trade
    function retreiveCryptomon(uint id) public onlyOwnerOf(id) {
        require(
            id < totalCryptomons,
            "Id out of range"
        );
        require(
            cryptomons[id].forSale
        );
        cryptomons[id].price = 0;
        cryptomons[id].forSale = false;
    }

    // Only the cryptomons listed on market are able to trade
    function buyCryptomon(uint id) public payable {
        require(
            cryptomons[id].forSale
        );
        require(
            id < totalCryptomons
        );
        require(
            msg.value >= cryptomons[id].price
        );

        address payable seller = cryptomons[id].owner;
        address payable sender = msg.sender;
        cryptomons[id].owner = sender;
        cryptomons[id].forSale = false;
        cryptomons[id].price = 0;
        require(balanceOf[seller]  < 2**256 - 1 - msg.value);
        balanceOf[seller] += msg.value;
        seller.transfer(msg.value);
    }


    // Sharing cryptomons
    function sharingCryptomon(uint id, uint32 requiredPokedexId, uint32 level, uint32 gender) public onlyOwnerOf(id) {
        require(
            requiredPokedexId < totalBaseCryptomons,
            'Cryptomon Not Found'
        );
        require(level >= 0 && (gender <= 1));
        require(
            getCoolDownStatus(id), 'Still Cooling Down'
        );
        require(
            !getFightStatus(id), 'Still in Fight Club'
        );
        cryptomons[id].properties['exchangePokedexId'] = requiredPokedexId;
        cryptomons[id].properties['exchangeLevel'] = level;
        cryptomons[id].properties['exchangeGender'] = gender;
    }

    // Exchange with sharing cryptomons
    function exchangeCryptomons(uint id, uint target) public onlyOwnerOf(id) {
        require(
            getCoolDownStatus(id), 'Still Cooling Down'
        );
        require(
            !getFightStatus(id), 'Still in Fight Club'
        );
        require(
            !getFightStatus(target), 'Still in Fight Club'
        );
        require(
            cryptomons[id].properties['pokedexId'] == cryptomons[target].properties['exchangePokedexId']
        );
        require(
            cryptomons[id].level >= cryptomons[target].properties['exchangeLevel']
        );
        require(
            uint32(cryptomons[id].gender) == cryptomons[target].properties['exchangeGender']
        );
        
        cryptomons[target].properties['exchangePokedexId'] = 0;
        cryptomons[target].properties['exchangeLevel'] = 0;
        cryptomons[target].properties['exchangeGender'] = 0;
        cryptomons[id].owner = cryptomons[target].owner;
        cryptomons[target].owner = msg.sender;
    }


    // View properties
    function getExchangePokedexId(uint id) public view returns (uint32) {
        return cryptomons[id].properties['exchangePokedexId'];
    }
    function getExchangeLevel(uint id) public view returns (uint32) {
        return cryptomons[id].properties['exchangeLevel'];
    }
    function getExchangeGender(uint id) public view returns (uint32) {
        return cryptomons[id].properties['exchangeGender'];
    }

    function getShareStatus(uint id) public view returns (bool) {
        return cryptomons[id].properties['exchangePokedexId'] == 0;
    }
    function cancelSharingCryptomon(uint id) public onlyOwnerOf(id) returns (bool) {
        cryptomons[id].properties['exchangePokedexId'] = 0;
        cryptomons[id].properties['exchangeLevel'] = 0;
        cryptomons[id].properties['exchangeGender'] = 0;
    }

}