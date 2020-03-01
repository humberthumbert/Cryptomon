pragma solidity ^0.5.11;

import "./cryptomons.sol";

contract CryptomonsBreed is Cryptomons{
    
    modifier onlyOwnerOf(uint cryptomonId) {
        require(
            msg.sender == cryptomons[cryptomonId].owner,
            'You are not the owner'
        );
        _;
    }

    function _triggerCooldown(Cryptomon storage cryptomon) internal {
        cryptomon.properties['readyTime'] = uint32(now + cryptomon.properties['requireCoolDown']);
    }

    function _distributeLevelPoints(uint cryptomonId, uint16 points) private {
        Cryptomon storage cryptomon = cryptomons[cryptomonId];
        if (points > 0) {
            uint16 hpPoints = 0;
            uint16 atkPoints = 0;
    
            hpPoints = uint16(rand(points, cryptomonId));
            if (points-hpPoints > 0){
                atkPoints = uint16(rand(points-hpPoints, cryptomonId));
            }
            addHP(cryptomon, hpPoints);
            addATK(cryptomon, atkPoints);
            addDEF(cryptomon, points-hpPoints-atkPoints);
        }
    }

    function breed(uint cryptomonId1, uint cryptomonId2) public onlyOwnerOf(cryptomonId1) onlyOwnerOf(cryptomonId2) returns (uint){
        require(getCoolDownStatus(cryptomonId1), "Cryptomon is not ready yet.");
        require(getCoolDownStatus(cryptomonId2), "Cryptomon is not ready yet.");
        require(getPokedexId(cryptomonId1) == getPokedexId(cryptomonId2), 'Cryptomons are not from the same species');
        require(cryptomons[cryptomonId1].gender != cryptomons[cryptomonId2].gender, 'Cryptomons have to be different gender');

        Cryptomon storage cryptomon1 = cryptomons[cryptomonId1];
        Cryptomon storage cryptomon2 = cryptomons[cryptomonId2];
        uint pokedexId = getPokedexId(cryptomonId1);
        uint16 level = cryptomon1.level > cryptomon2.level ? cryptomon2.level : cryptomon1.level;
        uint newCryptomonId = createCryptomon(pokedexId-1, level);

        _distributeLevelPoints(newCryptomonId, level / 2);
        _triggerCooldown(cryptomon1);
        _triggerCooldown(cryptomon2);

        return newCryptomonId;
    }

    function addHP(Cryptomon storage cryptomon, uint16 pointsToAdd) internal{
        cryptomon.properties['maxHP'] += pointsToAdd;
        cryptomon.properties['HP'] = cryptomon.properties['maxHP'];
    }

    function addATK(Cryptomon storage cryptomon, uint16 pointsToAdd) internal{
        cryptomon.properties['ATK'] += pointsToAdd;
    }

    function addDEF(Cryptomon storage cryptomon, uint16 pointsToAdd) internal{
        cryptomon.properties['DEF'] += pointsToAdd;
    }
}