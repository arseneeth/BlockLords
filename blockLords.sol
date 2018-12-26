pragma solidity ^0.4.24;

import "browser/Ownable.sol";

contract LordsContract is Ownable {


/////////////////////////////////////   MISC    ////////////////////////////////////////////////    

uint duration8Hours = 28800;      // 28_800 Seconds are 8 hours
uint duration12Hours = 43200;     // 43_200 Seconds are 12 hours
uint duration24Hours = 86400;     // 86_400 Seconds are 24 hours


function withdraw(uint amount) onlyOwner public returns(bool) { // only contract's owner can withdraw to owner's address
        address owner_ = owner();
        owner_.transfer(amount);
        return true;    
}

function random(uint entropy, uint number) private view returns (uint8) {   // NOTE: This random generator is not entirely safe and could potentially compromise the game, 
                                                               // I would recommend game owners to use solutions from trusted oracles
       return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%number);
   }

function randomFromAddress(address entropy) private view returns (uint8) {  
       return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%256);
   }

////////////////////////////////////////////////////////////////////////////////////////////////////    

///////////////////////////////////// HERO STRUCT ////////////////////////////////////////////////    

// TODO: implement item alike create hero functionality 

    struct Hero{
        address OWNER;     // Wallet address of Player that owns Hero
        uint TROOPS_CAP;   // Troops limit for this hero
        uint LEADERSHIP;   // Leadership Stat value
        uint INTELLIGENCE; // Intelligence Stat value
        uint STRENGTH;     // Strength Stat value
        uint SPEED;        // Speed Stat value
        uint DEFENSE;      // Defense Stat value
        // bytes32 TX;      // Transaction ID where Hero creation was recorded
    }
    
    mapping (uint => Hero) heroes;
    
    function putHero(uint id, address owner, uint troopsCap, uint leadership,  uint intelligence, uint strength, uint speed, uint defense) public onlyOwner { 
            require(id > 0,
            "Please insert id higher than 0");
            require(heroes[id].OWNER == 0x0000000000000000000000000000000000000000,
            "Hero with this id already exists");

            heroes[id] = Hero(owner, troopsCap, leadership,  intelligence, strength, speed, defense);
    }
    
    function getHero(uint id) public view returns(address, uint, uint, uint, uint, uint, uint){ 
            return (heroes[id].OWNER, heroes[id].TROOPS_CAP, heroes[id].LEADERSHIP, heroes[id].INTELLIGENCE, heroes[id].STRENGTH, heroes[id].SPEED, heroes[id].DEFENSE);
        }

////////////////////////////////////////////////////////////////////////////////////////////////////    

///////////////////////////////////// ITEM STRUCT //////////////////////////////////////////////////   

    struct Item{

        bytes32 STAT_TYPE; // Item can increase only one stat of Hero, there are five: Leadership, Defense, Speed, Strength and Intelligence
        bytes32 QUALITY; // Item can be in different Quality. Used in Gameplay.
        
        uint GENERATION; // Items are given to Players only as a reward for holding Strongholds on map, or when players create a hero.
                         // Items are given from a list of items batches. Item batches are putted on Blockchain at once by Game Owner.
                         // Each of Item batches is called as a generation.

        uint STAT_VALUE;
        uint LEVEL;
        uint XP;         // Each battle where, Item was used by Hero, increases Experience (XP). Experiences increases Level. Level increases Stat value of Item
        address OWNER;   // Wallet address of Item owner.
    }
    
    mapping (uint => Item) items;

    // creationType StrongholdReward: 0, createHero 1
    function putItem(uint creationType, uint id, bytes32 statType, bytes32 quality, uint generation, uint statValue, uint level, uint xp, address owner ) public onlyOwner { // only contract owner can put new items
            require(id > 0,
            "Please insert id higher than 0");

            items[id] = Item(statType, quality, generation, statValue, level, xp, owner);
            
            if (creationType == 0){
                addStrongholdReward(id);     //if putItem(stronghold reward) ==> add to StrongholdReward
            }
        }

    function getItem(uint id) public view returns(bytes32, bytes32, uint, uint, uint, uint, address){
            return (items[id].STAT_TYPE, items[id].QUALITY, items[id].GENERATION, items[id].STAT_VALUE, items[id].LEVEL, items[id].XP, items[id].OWNER);
        }
    
    function updateItemsStats(uint[] itemIds) public {
        for (uint i=0; i < itemIds.length ; i++){
            
            uint id = itemIds[i];
            Item storage item = items[id];
            uint seed = item.GENERATION+item.LEVEL+item.STAT_VALUE+item.XP + itemIds.length + randomFromAddress(item.OWNER); // my poor attempt to make the random generation a little bit more random

            // Increase XP that represents on how many battles the Item was involved into
            item.XP = item.XP + 1;
            
            // Increase Level
            if (item.QUALITY == 1 && item.LEVEL == 3 ||
                item.QUALITY == 2 && item.LEVEL == 5 ||
                item.QUALITY == 3 && item.LEVEL == 7 ||
                item.QUALITY == 4 && item.LEVEL == 9 ||
                item.QUALITY == 5 && item.LEVEL == 10){
                    // return "The Item reached max possible level. So do not update it";
                    continue;
            } if (
                item.LEVEL == 1 && item.XP >= 4 ||
                item.LEVEL == 2 && item.XP >= 14 ||
                item.LEVEL == 3 && item.XP >= 34 ||
                item.LEVEL == 4 && item.XP >= 74 ||
                item.LEVEL == 5 && item.XP >= 144 ||
                item.LEVEL == 6 && item.XP >= 254 ||
                item.LEVEL == 7 && item.XP >= 404 ||
                item.LEVEL == 8 && item.XP >= 604 ||
                item.LEVEL == 9 && item.XP >= 904
                ) {
                    
                    item.LEVEL = item.LEVEL + 1;
                    // return "Item level is increased by 1";
            } 
            // Increase Stats based on Quality
            if (item.QUALITY == 1){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3);
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 3;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 6;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 9;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 12;
            }

        }
        
    }
    
////////////////////////////////////////////////////////////////////////////////////////////////////////    

///////////////////////////////////// MARKET ITEM STRUCT ///////////////////////////////////////////////   

    struct MarketItemData{
        
            uint Price; // Fixed Price of Item defined by Item owner
            uint AuctionDuration; // 8, 12, 24 hours
            uint AuctionStartedTime; // Unix timestamp in seconds
            uint City; // City ID (item can be added onto the market only through cities.)
            address Seller; // Wallet Address of Item owner
            // bytes32 TX; // Transaction ID, (Transaction that has a record of Item Adding on Market)

    }

    mapping (uint => MarketItemData) market_items_data;

    function auctionBegin(uint itemId, uint price, uint auctionDuration, uint city) public { // START AUCTION FUNCTION
            require(items[itemId].OWNER == msg.sender, 
            "You don't own this item");
            require(auctionDuration == duration8Hours || auctionDuration == duration12Hours || auctionDuration == duration24Hours,
            "Incorrect auction duration");
            address seller = msg.sender; 
            uint auctionStartedTime = now;
            market_items_data[itemId] = MarketItemData(price, auctionDuration, auctionStartedTime, city, seller);
        }
    
    function getAuctionData(uint itemId) public view returns(uint, uint, uint, uint, address){
            return(market_items_data[itemId].Price, market_items_data[itemId].AuctionDuration, market_items_data[itemId].AuctionStartedTime, market_items_data[itemId].City, market_items_data[itemId].Seller);
    }

    function auctionEnd(uint itemId) public payable returns(bool) {
        require(market_items_data[itemId].AuctionStartedTime+market_items_data[itemId].AuctionDuration>=now,
        "Auction is no longer available"); // check  auction duration time
        require(msg.value == market_items_data[itemId].Price,
        "The value sent is incorrect"); // check transaction amount
        
        uint city = market_items_data[itemId].City; // get the city id
        
        uint cityHero = cities[city].Hero;  // get the hero id
        address cityOwner = heroes[cityHero].OWNER; // get the hero owner
        address seller = market_items_data[itemId].Seller;
        
        uint amount = msg.value;
        
        cityOwner.transfer(amount/20); // send 5% to city owner
        seller.transfer(amount*9/10); // send 90% to seller
        
        items[itemId].OWNER = msg.sender; // change owner
        delete market_items_data[itemId]; // delete auction
        return (true); 
        
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
///////////////////////////////////// CITY STRUCT //////////////////////////////////////////////////////////   

    struct City{
        
        uint ID;
        uint Hero;
        uint Size; // BIG, MEDIUM, SMALL
        
    }

    mapping(uint => City) cities;

    function changeCityOwner(uint id, uint hero, uint size) public {
            require(id > 0,
            "Please insert id higher than 0");
            require(heroes[hero].OWNER == msg.sender,
            "You don't own this hero");
            cities[id] = City(id, hero, size);
    }
    
    function getCityData(uint id) public view returns(uint, uint){
        return (cities[id].Hero, cities[id].Size);
        
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
///////////////////////////////////// STRONGHOLD STRUCT //////////////////////////////////////////////////////////   

    struct Stronghold{
        uint ID;           // Stronghold ID
        uint Hero;         // Hero ID, that occupies Stronghold on map
        uint CreatedBlock; // The Blockchain Height
      
    }
    
    Stronghold[10] public strongholds;

    mapping(uint => Stronghold[10]) public idToStronghold;

    function changeStrongholdOwner(uint id, uint hero) public {
            require(heroes[hero].OWNER != 0x0000000000000000000000000000000000000000,
            "There is no such hero");
            require(heroes[hero].OWNER == msg.sender,
            "You dont own this hero");
            
            strongholds[id] = Stronghold(id, hero, block.number); // Stronghold ID is the only id that starts from 0, all other id's start from 1
    }
    
    function getStrongholdData(uint shId) public view returns(uint, uint){
            return(strongholds[shId].Hero, strongholds[shId].CreatedBlock);
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// STRONGLOHD REWARD STRUCT /////////////////////////////////////////////////////////

    struct StrongholdReward{
        
        uint ID;           // Item ID
        uint CreatedBlock; // The Blockchain Height
        
    }
    
    mapping (uint => StrongholdReward) stronghold_rewards;
    
    function addStrongholdReward(uint id) public onlyOwner returns(bool){
        stronghold_rewards[id] = StrongholdReward(id, block.number);
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// BATTLELOG STRUCT /////////////////////////////////////////////////////////

    struct BattleLog{

        uint[] BattleResultType; // BattleResultType[0]: 0 - Attacker WON, 1 - Attacker Lose ; BattleResultType[1]: 0 - City, 1 - Stronghold, 2 - Bandit Camp
        uint Attacker;
        uint[] AttackerTroops;       // Attacker's troops amount that were involved in the battle & remained troops
        uint[] AttackerItems;        // Item IDs that were equipped by Attacker during battle.
        uint DefenderObject;   // City|Stronghold|NPC ID based on battle type
        uint Defender;         // City Owner ID|Stronghold Owner ID or NPC ID
        uint[] DefenderTroops;
        uint[] DefenderItems;
        uint Time;             // Unix Timestamp in seconds. Time, when battle happened 
        // bytes32 TX;                   // Transaction where Battle Log was recorded.
        }
        
    mapping(uint => BattleLog) battle_logs;
    
    function addBattleLog(uint id, uint[] resultType, uint attacker, uint[] attackerTroops, uint[] attackerItems, 
                          uint defenderObject, uint defender, uint[] defenderTroops, uint[] defenderItems) public returns (bool){
                        
                        require(resultType.length <=2 && resultType[0] <= 1 && resultType[1] <= 2 ,
                                "Incorrect number of result parametres or incorrect parametres");
                        require(attackerTroops.length <=2,
                                "Incorrect number of arguments for attackerTroops");
                        require(attackerItems.length <= 5 && defenderItems.length <=5,
                                "incorrect number of attacker items");
                        require(defenderTroops.length <=2,
                                "Incorrect number of arguments for defenderTroops");
                        require(defenderItems.length <= 5 && defenderItems.length <=5,
                                "incorrect number of defender items");

                        // address attackerOwner = heroes[attacker].OWNER;
                        // address defenderOwner = heroes[defender].OWNER;
                        uint time = now;
                        
                        battle_logs[id] = BattleLog(resultType, attacker, attackerTroops, 
                                                    attackerItems, defenderObject, defender, 
                                                    defenderTroops, defenderItems, time); //add data to the struct 
                                                    
                        if (resultType[0] == 0 && resultType[1] == 1){ 
                            strongholds[defenderObject].Hero = attacker; // if attack Stronghold && WIN ==> change stronghold Owner
                            return(true);
                        } else if (resultType[0] == 0 && resultType[1] == 0) {
                            cities[defenderObject].Hero = attacker; // else if attack City && WIN ==> change city owner
                            return(true);
                        } else if (resultType[1] == 2){
                            updateItemsStats(attackerItems);     // else if attackBandit ==> update item stats
                        } 
                        return true;
    }


////////////////////////////////////////// DROP DATA STRUCT ///////////////////////////////////////////////////
    
    struct DropData{       // Information of Item that player can get as a reward.
        uint Block;        // Blockchain Height, in which player got Item as a reward
        uint StrongholdId; // Stronghold on the map, for which player got Item
        uint ItemId;       // Item id that was given as a reward
        uint HeroId;
    }

    uint blockNumber = block.number;
    uint isAllowed = 1;
    uint blockDistance = 3; // change to 120


    function dropItems(uint itemNumber) public onlyOwner returns(string) {
        // TODO: check if item is StrongholdReward
        require(stronghold_rewards[itemNumber].ID > 0,
        "Not a reward item");
        require(block.number-blockNumber > blockDistance,
        "Please try again later");
                
        blockNumber = block.number; // this function can be called every "blockDistance" blocks
        uint strongholdNumber = random(randomFromAddress(msg.sender), 10)-1; // select randomly stronghold
        uint strongholdHero = strongholds[strongholdNumber].Hero;
        if (strongholdHero > 0){
           items[itemNumber].OWNER = heroes[strongholdHero].OWNER;
           delete stronghold_rewards[itemNumber];//delete item from strongHold reward struct
           return("Supreme success!"); // check if hero exist
        } else {
            return ("No success");
        }
    }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// TODO:

// cancell auction

// CityPayout
// LogStronghold Leave
// put city data `9invoked by smartcontract owner
// cancel auction



}