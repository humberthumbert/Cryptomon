pragma solidity ^0.5.11;

import "./cryptomonsBreed.sol";

contract CryptomonsFight is CryptomonsBreed{

    // Need to check if the other is listed forFight
    // If is listed, check if the opposite is against. max as first time allow getting in
    modifier readyFighting(uint id, uint against){
        require(
            cryptomons[id].forFight && (cryptomons[id].fightAgainst == against || cryptomons[id].fightAgainst == max),
            'The target cryptomon is not ready for fight'
        );
        _;
    }

    function addPoint(uint cryptomonId, uint8 attribute) public onlyOwnerOf(cryptomonId) {
        require(
            cryptomons[cryptomonId].winPoint >= levelUpPoint,
            'Not enough winPoint to level up'
        );
        Cryptomon storage cryptomon = cryptomons[cryptomonId];
        cryptomon.winPoint -= levelUpPoint;
        cryptomon.level++;
        if(attribute == 0) {
            addHP(cryptomon, 1);
        } else if(attribute == 1) {
            addATK(cryptomon, 1);
        } else {
            addDEF(cryptomon, 1);
        }
    }

    /*
        For Winner: 1. Get one winPoint
                    2. Reset fightAgainst
                    3. Check if level up
        For Loser:  1. Reset fightAgainst
                    2. Remove from forFight
                    3. Reset readyTime
                    4. HP set to zero
    */
    function _fightSummary(uint winnerId, uint loserId) private returns (bool){

        cryptomons[loserId].fightAgainst = max;
        cryptomons[loserId].properties['HP'] = 0;
        cryptomons[loserId].properties['readyTime'] = uint32(now + cryptomons[loserId].properties['requireCoolDown']);
        cryptomons[loserId].forFight = false;

        cryptomons[winnerId].fightAgainst = max;
        cryptomons[winnerId].winPoint++;
        if (cryptomons[winnerId].winPoint >= levelUpPoint) {
            cryptomons[winnerId].properties['requireCoolDown'] += cryptomons[winnerId].level * 60;
            return true;
        }
        return false;
    }
    /*
        target first attack on cryptomon
    */
    function fightCryptomon(uint target, uint cryptomonId) public onlyOwnerOf(cryptomonId) readyFighting(target, cryptomonId) {
        require(getCoolDownStatus(cryptomonId), 'Your cryptomon is Still Cooling Down');
        require(getCoolDownStatus(target), 'Target cryptomon is Still Cooling Down');
        if (cryptomons[cryptomonId].fightAgainst != max) {
            cryptomons[cryptomonId].fightAgainst = target;
        }
        if (cryptomons[target].fightAgainst != max) {
            cryptomons[target].fightAgainst = cryptomonId;
        }
        uint32 damage1 = cryptomons[target].properties['ATK'] > cryptomons[cryptomonId].properties['DEF'] ? cryptomons[target].properties['ATK'] - cryptomons[cryptomonId].properties['DEF'] : 0;
        uint32 damage2 = cryptomons[cryptomonId].properties['ATK'] > cryptomons[target].properties['DEF'] ? cryptomons[cryptomonId].properties['ATK'] - cryptomons[target].properties['DEF'] : 0;
        uint32 hp1 = cryptomons[target].properties['HP'];
        uint32 hp2 = cryptomons[cryptomonId].properties['HP'];
        if (damage1 > 0 || damage2 > 0){
            if (damage1 == 0){
                _fightSummary(target, cryptomonId);
            } else if (damage2 == 0){
                _fightSummary(cryptomonId, target);
            } else if (hp2 / damage1 > hp1 / damage2){
                cryptomons[cryptomonId].properties['HP'] -= hp1 / damage2 * damage1;
                _fightSummary(cryptomonId, target);
            } else {
                cryptomons[target].properties['HP'] -= hp2 / damage1 * damage2;
                _fightSummary(target, cryptomonId);
            }
        }
    }
    
    // getFightStatus
    function getFightStatus(uint id) public view returns (bool) {
        return cryptomons[id].forFight && (cryptomons[id].fightAgainst != max);
    }

    function setForFight(uint id, bool forFight) public onlyOwnerOf(id){
        require(
            getCoolDownStatus(id),
            'Not ready for Fight'
        );
        cryptomons[id].forFight = forFight;
    }

}
