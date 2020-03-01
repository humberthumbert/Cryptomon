pragma solidity ^0.5.11;

import "./ownable.sol";

contract Cryptomons is Ownable {
    enum Gender { MALE, FEMALE }
    struct Cryptomon {
        uint id;
        address payable owner;
        Gender gender;
        bool forSale;
        bool forFight;
        uint16 level;
        uint16 winPoint;
        uint fightAgainst;
        uint price;
        mapping(string => uint32) properties;
    }
    uint lastCheckTime = now;
    // Storage information
    mapping(uint => Cryptomon) public baseCryptomons;
    uint public totalBaseCryptomons = 0;
    uint baseMax = 2**256 - 1;

    mapping(uint => Cryptomon) public cryptomons;
    uint public totalCryptomons = 0;
    uint max = 2**256 - 1;

    mapping (address => uint) public balanceOf;
    
    // Tunable data
    uint lotteryFee = 1e17;
    uint8 lotteryRound = 5;
    uint16 levelUpPoint = 10;

    function buildCard(uint16 pokedexId, uint16 HP, uint16 ATK, uint16 DEF, uint16 requireCoolDown) public onlyOwner returns (uint) {
        require(
            totalBaseCryptomons <= baseMax,
            "More than Max Number"
        );
        require(
            pokedexId <= baseMax,
            'More than Max Number'
        );
        Cryptomon storage cryptomon = baseCryptomons[totalBaseCryptomons];
        cryptomon.id = totalBaseCryptomons;
        cryptomon.owner = owner;
        cryptomon.gender = Gender.MALE;
        cryptomon.forFight = false;
        cryptomon.forSale = false;
        cryptomon.price = 0;
        cryptomon.fightAgainst = max;
        cryptomon.level = 2;
        cryptomon.winPoint = 0;
        cryptomon.properties['pokedexId'] = pokedexId;
        cryptomon.properties['HP'] = HP;
        cryptomon.properties['ATK'] = ATK;
        cryptomon.properties['DEF'] = DEF;
        cryptomon.properties['requireCoolDown'] = requireCoolDown;
        cryptomon.properties['readyTime'] = uint32(now);
        cryptomon.properties['maxHP'] = HP;
        cryptomon.properties['exchangePokedexId'] = 0;
        cryptomon.properties['exchangeLevel'] = 0;
        cryptomon.properties['exchangeGender'] = 0;

        totalBaseCryptomons++;

        return cryptomon.id;
    }

    function createCryptomon(uint pokedexId, uint16 level) internal returns (uint){
        require(
            totalCryptomons <= max-1,
            "More than Max Number"
        );
        require(
            pokedexId <= max-1,
            "More than Max Number"
        );
        // Read From BaseCryptomon
        Cryptomon storage baseCryptomon = baseCryptomons[pokedexId];
        // Duplicate the attribute
        Cryptomon storage cryptomon = cryptomons[totalCryptomons];
        cryptomon.id = totalCryptomons;
        cryptomon.owner = msg.sender;
        cryptomon.gender = rand(2,totalCryptomons) == 1 ? Gender.MALE : Gender.FEMALE;
        cryptomon.forFight = false;
        cryptomon.forSale = false;
        cryptomon.fightAgainst = max;
        cryptomon.price = 0;
        cryptomon.level = level / 2 == 0? 1 : level/2;
        cryptomon.winPoint = 0;
        cryptomon.properties['pokedexId'] = baseCryptomon.properties['pokedexId'];
        cryptomon.properties['HP'] = baseCryptomon.properties['HP'];
        cryptomon.properties['ATK'] = baseCryptomon.properties['ATK'];
        cryptomon.properties['DEF'] = baseCryptomon.properties['DEF'];
        cryptomon.properties['requireCoolDown'] = baseCryptomon.properties['requireCoolDown'];
        cryptomon.properties['readyTime'] = baseCryptomon.properties['lastCoolDown'];
        cryptomon.properties['maxHP'] = baseCryptomon.properties['maxHP'];
        cryptomon.properties['exchangePokedexId'] = 0;
        cryptomon.properties['exchangeLevel'] = 0;
        cryptomon.properties['exchangeGender'] = 0;

        totalCryptomons++;
        return cryptomon.id;
    }
    // withdraw
    function withdraw() external {
        uint256 amount = balanceOf[msg.sender];
        balanceOf[msg.sender] = 0;
        (bool success, ) = msg.sender.call.value(amount)("");
        require(success, "Transfer failed.");
    }

    // Lottery Part (AKA generate)
    function lotteryCryptomon() public payable{
        require(
            totalBaseCryptomons != 0,
            'The contract has not yet constructed'
        );
        require(
            totalCryptomons + lotteryRound < max,
            "Unable to have more cryptmon"
        );
        require(
            msg.value >= lotteryFee,
            "Not enough money"
        );
        //uint[] memory newCryptomons = new uint[](lotteryRound);
        for(uint i = 0; i < lotteryRound; i++) {
            uint randomIndex = rand(totalBaseCryptomons, i*256);
            createCryptomon(randomIndex, 1);
            
        }
        require(balanceOf[owner]  < 2**256 - 1- msg.value);
        balanceOf[owner] += msg.value;
        owner.transfer(msg.value);
        // return newCryptomons;
    }
    function setLotteryFee(uint newFee) public onlyOwner {
        lotteryFee = newFee;
    }
    
    // View properties
    function getPokedexId(uint id) public view returns (uint) {
        return cryptomons[id].properties['pokedexId'];
    }
    function gethp(uint id) public view returns (uint32) {
        return cryptomons[id].properties['HP']; 
    }
    function getHP(uint id) public returns (uint32) {
        if (cryptomons[id].properties['HP'] != cryptomons[id].properties['maxHP'] ) {
            uint32 maxHP = cryptomons[id].properties['maxHP'];
            uint32 coolDownTime = cryptomons[id].properties['requireCoolDown'];
            uint32 elapseTime = uint32(coolDownTime + now - cryptomons[id].properties['readyTime']); // UInt Math?
            cryptomons[id].properties['HP'] = cryptomons[id].properties['HP'] + elapseTime * maxHP / coolDownTime;
            if (cryptomons[id].properties['HP'] > cryptomons[id].properties['maxHP']) {
                cryptomons[id].properties['HP'] = cryptomons[id].properties['maxHP'];
            }
        }
        return cryptomons[id].properties['HP'];
    }
    function getATK(uint id) public view returns (uint32) {
        return cryptomons[id].properties['ATK'];
    }
    function getDEF(uint id) public view returns (uint32) {
        return cryptomons[id].properties['DEF'];
    }
    function getMaxHP(uint id) public view returns (uint32) {
        return cryptomons[id].properties['maxHP'];
    }
    function getCoolDownStatus(uint id) public returns (bool) {
        // return true if is ready
        lastCheckTime = now;
        return (now >= cryptomons[id].properties['readyTime']);
    }
    function getReadyTime(uint id) public view returns (uint32) {
        // beaware of uint32 math
        return cryptomons[id].properties['readyTime'];
    }
    
    function getRequiredCoolDown(uint id) public view returns (uint32) {
        return cryptomons[id].properties['requireCoolDown'];
    }
    function getLotteryFee() public view returns (uint) {
        return lotteryFee;
    }
    
    // Random Function taht based on time which is not that safe
    function rand(uint256 _length, uint seed) public view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, now+seed)));
        return random%_length;
    }
}