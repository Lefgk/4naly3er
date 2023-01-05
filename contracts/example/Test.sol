// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0; // solhint-disable-line


contract ShrimpFarmer  {
    

    uint256 public constant EGGS_TO_HATCH_1SHRIMP = 86400; //86400 sec
    uint256 public constant VRF_EGG_COST = (1000000000000000000 * 300) / EGGS_TO_HATCH_1SHRIMP;
    uint256 PSN = 100000000000000;
    uint256 PSNH = 50000000000000;
    uint256 public potDrainTime = 2 hours; 
    uint256 public POT_DRAIN_INCREMENT = 1 hours;
    uint256 public POT_DRAIN_MAX = 3 days;
    uint256 public HATCH_COOLDOWN_MAX = 6 hours; //6 hours;
    bool public initialized;

    uint256 public index;
    mapping(address => uint256) private isPlayer;
    address[] public players;
    uint256 public refAmount=10;
    address payable immutable public dev;
    mapping(address => uint256) public hatchCooldown; //the amount of time you must wait now varies per user
    mapping(address => uint256) public hatcheryShrimp;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => uint256) public totalBoughtEggs;
    mapping(address => bool) public hasClaimedFree;
    mapping(address => address) public referrals;
    uint256 public marketEggs;
    uint256 public FinalPrize;

    uint256 public lastBidTime; //last time someone bid for the pot
    address payable public currentWinner;
    uint256 public totalHatcheryShrimp;
    uint256 public prize;

    constructor() payable {
        dev = payable(msg.sender);
        lastBidTime = block.timestamp;
        currentWinner = payable(msg.sender);
    }

    function storeFunders(address player) internal {
        players.push(player);
        isPlayer[player] = 1;
        index++;
    }

    function _isContract(address addr) public view returns (uint256) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size ;
    }

    function changerefAmount(uint256 _refAmount) external  {
        refAmount=_refAmount;
    }

    function finalizeIfNecessary() public {
        if (lastBidTime + potDrainTime < block.timestamp) {
            FinalPrize=address(this).balance;
            uint256 winneramount = (address(this)).balance*60/100;
            uint256 winneramount2 = (address(this)).balance-winneramount;
            currentWinner.transfer(winneramount); //winner gets everything
            dev.transfer(winneramount2); //dev gets everything
            initialized = false;
        }
    }

/*
    function getWinners() public {
        uint256 _total;
        for (uint256 i = 0; i <= index ; ) {
            _total += dayDivendPool[_startDay + i];
            unchecked {
                 i++;
            }
        }
    }
    */
    function getPotCost() internal view returns (uint256) {
        return totalHatcheryShrimp/(100);
    }

    function stealPot() public {
        require (currentWinner != msg.sender,'you cant');
           finalizeIfNecessary();
        if (!initialized) {return;}
                else {
            uint256 cost = getPotCost();
            require(hatcheryShrimp[msg.sender] >= cost, 'not enough shrimps');
            _hatchEggs(address(0),1); //1 means external
            hatcheryShrimp[msg.sender] = hatcheryShrimp[msg.sender]-(cost); //cost is 1% of total shrimp
            totalHatcheryShrimp = totalHatcheryShrimp-(cost);
            setNewPotWinner();
            // hatchCooldown[msg.sender] = 0;
        }
    }

    function setNewPotWinner() internal {
        finalizeIfNecessary();
        if (initialized && msg.sender != currentWinner) {
            potDrainTime = potDrainTime+lastBidTime + POT_DRAIN_INCREMENT - block.timestamp; //time left plus one hour
            if (potDrainTime > POT_DRAIN_MAX) {
                potDrainTime = POT_DRAIN_MAX;
            }
            hatchCooldown[msg.sender] = 0;
            lastBidTime = block.timestamp;
            currentWinner = payable(msg.sender);
        }
    }

    function _hatchEggs(address ref, uint256 isintern) internal {
        require(initialized, 'not initialised');
        require(ref != msg.sender, 'cant self-ref');
        uint256 eggsUsed = getMyEggs(msg.sender);
        uint256 newShrimp = eggsUsed / EGGS_TO_HATCH_1SHRIMP;
        hatcheryShrimp[msg.sender] += newShrimp;
        totalHatcheryShrimp += newShrimp;
        claimedEggs[msg.sender] = 0;
        totalBoughtEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        hatchCooldown[msg.sender] = HATCH_COOLDOWN_MAX;
        //if direct hatch :
        if (isintern==0) {
           
            // if ref provided==0 and another ref already stored and he has claimed free
            if (ref == address(0) && referrals[msg.sender] != address(0) && hasClaimedFree[referrals[msg.sender]]) {

                hatcheryShrimp[referrals[msg.sender]] += refAmount * newShrimp / 100;
                totalHatcheryShrimp += refAmount * newShrimp / 100;

            // if ref provided==0 and no ref stored
            } else if (ref == address(0) && referrals[msg.sender] == address(0)) {
                // hatcheryShrimp[referrals[msg.sender]] += newShrimp / 10;
                // totalHatcheryShrimp += newShrimp  / 10;

            // if ref provided 
            } else  {
                if(ref != referrals[msg.sender]) referrals[msg.sender] = ref; // store ref or replaced
                // if he has claimed free he gets 10%
                if (hasClaimedFree[ref]) {
                    hatcheryShrimp[ref] += refAmount * newShrimp / 100;
                    totalHatcheryShrimp += refAmount * newShrimp  / 100;
                }
            }
        }
        //boost market to nerf shrimp hoarding
        marketEggs += eggsUsed / 10;
    }

    function isHatchOnCooldown(address _sender) public view returns (bool) {
        return lastHatch[_sender]+(hatchCooldown[_sender]) < block.timestamp;
    }

    function hatchEggs(address ref) external {
        require(isHatchOnCooldown(msg.sender), 'hatch on cooldown');
        _hatchEggs(ref,0); //0 means external
    }

    function getHatchCooldown(uint256 eggs) public view returns (uint256) {
        uint256 targetEggs = marketEggs / 50;
        if (eggs >= targetEggs) {
            return HATCH_COOLDOWN_MAX;
        }
        return (HATCH_COOLDOWN_MAX*(eggs))/(targetEggs);
    }

    function reduceHatchCooldown(address addr, uint256 eggs) private {
        uint256 reduction = getHatchCooldown(eggs);
        if (reduction >= hatchCooldown[addr]) {
            hatchCooldown[addr] = 0;
        } else {
            hatchCooldown[addr] = hatchCooldown[addr]-(reduction);
        }
    }

    function sellEggs() external {
        require(initialized, 'not initialised');
        finalizeIfNecessary();
        if (!initialized) return;
        uint256 hasEggs = getMyEggs(msg.sender); 
        uint256 eggValue = calculateEggSell(hasEggs); 
        uint256 potfee = (20 * eggValue) / 100;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs += hasEggs;
        totalBoughtEggs[msg.sender] = 0;
        prize += potfee;
        payable(msg.sender).transfer(eggValue-(potfee));
    }

    function buyEggs() external payable {
        require(initialized, 'not initialised');
        finalizeIfNecessary();
        if (!initialized) return;

        if (isPlayer[msg.sender] == 0) storeFunders(msg.sender);

        uint256 eggsBought = calculateEggBuy(msg.value, (address(this).balance - msg.value));
        eggsBought = eggsBought-(((eggsBought * 4) / 100));
        dev.transfer(((msg.value * 4) / 100));
        payable(address(this)).transfer(msg.value - ((msg.value * 4) / 100));
        claimedEggs[msg.sender] = claimedEggs[msg.sender] + eggsBought;
        totalBoughtEggs[msg.sender] += eggsBought;
        reduceHatchCooldown(msg.sender, eggsBought); //reduce the hatching cooldown based on eggs bought

        //steal the pot if bought enough
        uint256 potEggCost = getPotCost()*(EGGS_TO_HATCH_1SHRIMP); //the equivalent number of eggs to the pot cost in shrimp
        if (eggsBought > potEggCost) {
            //hatcheryShrimp[msg.sender]=hatcheryShrimp[msg.sender]+(getPotCost());//to compensate for the shrimp that will be lost when calling the following

            setNewPotWinner();
        }
        
    }

    //magic trade balancing algorithm
    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) internal view returns (uint256) {
        return
       (PSN);
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance-(prize));
    }

    function calculateEggBuy(uint256 _BTTC, uint256 contractBalance) public view returns (uint256) {
        return calculateTrade(_BTTC, contractBalance - prize, marketEggs);
    }

    function calculateEggBuySimple(uint256 _BTTC) public view returns (uint256) {
        return calculateEggBuy(_BTTC, address(this).balance);
    }

    function seedMarket(uint256 eggs) public {
       
        require(!initialized);
        initialized = true;
        marketEggs = eggs;
        lastBidTime = block.timestamp;
    }

    function getWinner() public view returns (uint256) {
        return (lastBidTime+(potDrainTime) - block.timestamp);
    }

    function getMyHatchCoolDown() public view returns (uint256) {
        if (lastHatch[msg.sender]+(hatchCooldown[msg.sender]) > block.timestamp){
        return (lastHatch[msg.sender]+(hatchCooldown[msg.sender]) - block.timestamp);
        }
        else {
        return 0;
        }
    }
    fallback() external payable {}

    receive() external payable {}

    function claimFreeEggs(address _sender) public {
        require(initialized);
        require(!hasClaimedFree[_sender]);
        uint256 freeamount = getFreeEggs() < 86400 ? 86401 : getFreeEggs() ;
        claimedEggs[_sender] = claimedEggs[_sender]+(freeamount);
        _hatchEggs(address(0),1); // 1 means external
        hatchCooldown[_sender] = 0;
        hasClaimedFree[_sender] = true;
    }

    function getFreeEggs() public view returns (uint256) {
        return min(calculateEggBuySimple(address(this).balance/(400)), calculateEggBuySimple(0.01 ether));
    }

    function getMyShrimp(address _sender) public view returns (uint256) {
        return hatcheryShrimp[_sender];
    }

    function getAll() external  {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getMyEggs(address _sender) public view returns (uint256) {
        return claimedEggs[_sender]+getEggsSinceLastHatch(_sender);
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(EGGS_TO_HATCH_1SHRIMP, 1000);
        return secondsPassed* hatcheryShrimp[adr];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
