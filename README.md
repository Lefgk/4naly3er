# Report

## Gas Optimizations

|                 | Issue                                                                                                 | Instances |
| --------------- | :---------------------------------------------------------------------------------------------------- | :-------: |
| [GAS-1](#GAS-1) | Use `selfbalance()` instead of `address(this).balance`                                                |     6     |
| [GAS-2](#GAS-2) | Use assembly to check for `address(0)`                                                                |     4     |
| [GAS-3](#GAS-3) | `array[index] += amount` is cheaper than `array[index] = array[index] + amount` (or related variants) |     4     |
| [GAS-4](#GAS-4) | Using bools for storage incurs overhead                                                               |     2     |
| [GAS-5](#GAS-5) | Don't initialize variables with default value                                                         |     2     |
| [GAS-6](#GAS-6) | `++i` costs less gas than `i++`, especially when it's used in `for`-loops (`--i`/`i--` too)           |     2     |
| [GAS-7](#GAS-7) | Using `private` rather than `public` for constants, saves gas                                         |     2     |
| [GAS-8](#GAS-8) | Use shift Right/Left instead of division/multiplication if possible                                   |     1     |

### <a name="GAS-1"></a>[GAS-1] Use `selfbalance()` instead of `address(this).balance`

Use assembly when getting a contract's balance of ETH.

You can use `selfbalance()` instead of `address(this).balance` when getting your contract's balance of ETH to save gas.
Additionally, you can use `balance(address)` instead of `address.balance()` when getting an external contract's balance of ETH.

_Saves 15 gas when checking internal balance, 6 for external_

_Instances (6)_:

```solidity
File: example/Test.sol

62:             FinalPrize=address(this).balance;

201:         uint256 eggsBought = calculateEggBuy(msg.value, (address(this).balance - msg.value));

230:         return calculateTrade(eggs, marketEggs, address(this).balance-(prize));

238:         return calculateEggBuy(_BTTC, address(this).balance);

276:         return min(calculateEggBuySimple(address(this).balance/(400)), calculateEggBuySimple(0.01 ether));

284:         payable(msg.sender).transfer(address(this).balance);

```

### <a name="GAS-2"></a>[GAS-2] Use assembly to check for `address(0)`

_Saves 6 gas per instance_

_Instances (4)_:

```solidity
File: example/Test.sol

129:             if (ref == address(0) && referrals[msg.sender] != address(0) && hasClaimedFree[referrals[msg.sender]]) {

129:             if (ref == address(0) && referrals[msg.sender] != address(0) && hasClaimedFree[referrals[msg.sender]]) {

135:             } else if (ref == address(0) && referrals[msg.sender] == address(0)) {

135:             } else if (ref == address(0) && referrals[msg.sender] == address(0)) {

```

### <a name="GAS-3"></a>[GAS-3] `array[index] += amount` is cheaper than `array[index] = array[index] + amount` (or related variants)

When updating a value in an array with arithmetic, using `array[index] += amount` is cheaper than `array[index] = array[index] + amount`.
This is because you avoid an additonal `mload` when the array is stored in memory, and an `sload` when the array is stored in storage.
This can be applied for any arithmetic operation including `+=`, `-=`,`/=`,`*=`,`^=`,`&=`, `%=`, `<<=`,`>>=`, and `>>>=`.
This optimization can be particularly significant if the pattern occurs during a loop.

_Saves 28 gas for a storage array, 38 for a memory array_

_Instances (4)_:

```solidity
File: example/Test.sol

94:             hatcheryShrimp[msg.sender] = hatcheryShrimp[msg.sender]-(cost); //cost is 1% of total shrimp

175:             hatchCooldown[addr] = hatchCooldown[addr]-(reduction);

205:         claimedEggs[msg.sender] = claimedEggs[msg.sender] + eggsBought;

269:         claimedEggs[_sender] = claimedEggs[_sender]+(freeamount);

```

### <a name="GAS-4"></a>[GAS-4] Using bools for storage incurs overhead

Use uint256(1) and uint256(2) for true/false to avoid a Gwarmaccess (100 gas), and to avoid Gsset (20000 gas) when changing from ‘false’ to ‘true’, after having been ‘true’ in the past. See [source](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27).

_Instances (2)_:

```solidity
File: example/Test.sol

16:     bool public initialized;

28:     mapping(address => bool) public hasClaimedFree;

```

### <a name="GAS-5"></a>[GAS-5] Don't initialize variables with default value

_Instances (2)_:

```solidity
File: example/Test.sol

21:     uint256 public refAmount=10;

74:         for (uint256 i = 0; i <= index ; ) {

```

### <a name="GAS-6"></a>[GAS-6] `++i` costs less gas than `i++`, especially when it's used in `for`-loops (`--i`/`i--` too)

_Saves 5 gas per loop_

_Instances (2)_:

```solidity
File: example/Test.sol

47:         index++;

77:                  i++;

```

### <a name="GAS-7"></a>[GAS-7] Using `private` rather than `public` for constants, saves gas

If needed, the values can be read from the verified contract source code, or if there are multiple values there can be a single getter function that [returns a tuple](https://github.com/code-423n4/2022-08-frax/blob/90f55a9ce4e25bceed3a74290b854341d8de6afa/src/contracts/FraxlendPair.sol#L156-L178) of the values of all currently-public constants. Saves **3406-3606 gas** in deployment gas due to the compiler not having to create non-payable getter functions for deployment calldata, not having to store the bytes of the value outside of where it's used, and not adding another entry to the method ID table

_Instances (2)_:

```solidity
File: example/Test.sol

8:     uint256 public constant EGGS_TO_HATCH_1SHRIMP = 86400; //86400 sec

9:     uint256 public constant VRF_EGG_COST = (1000000000000000000 * 300) / EGGS_TO_HATCH_1SHRIMP;

```

### <a name="GAS-8"></a>[GAS-8] Use shift Right/Left instead of division/multiplication if possible

_Instances (1)_:

```solidity
File: example/Test.sol

276:         return min(calculateEggBuySimple(address(this).balance/(400)), calculateEggBuySimple(0.01 ether));

```

## Non Critical Issues

|               | Issue                                                                      | Instances |
| ------------- | :------------------------------------------------------------------------- | :-------: |
| [NC-1](#NC-1) | `require()` / `revert()` statements should have descriptive reason strings |     3     |
| [NC-2](#NC-2) | Constants should be defined rather than using magic numbers                |     2     |
| [NC-3](#NC-3) | Functions not used internally could be marked external                     |     7     |

### <a name="NC-1"></a>[NC-1] `require()` / `revert()` statements should have descriptive reason strings

_Instances (3)_:

```solidity
File: example/Test.sol

243:         require(!initialized);

266:         require(initialized);

267:         require(!hasClaimedFree[_sender]);

```

### <a name="NC-2"></a>[NC-2] Constants should be defined rather than using magic numbers

_Instances (2)_:

```solidity
File: example/Test.sol

185:         uint256 potfee = (20 * eggValue) / 100;

276:         return min(calculateEggBuySimple(address(this).balance/(400)), calculateEggBuySimple(0.01 ether));

```

### <a name="NC-3"></a>[NC-3] Functions not used internally could be marked external

_Instances (7)_:

```solidity
File: example/Test.sol

50:     function _isContract(address addr) public view returns (uint256) {

86:     function stealPot() public {

241:     function seedMarket(uint256 eggs) public {

249:     function getWinner() public view returns (uint256) {

253:     function getMyHatchCoolDown() public view returns (uint256) {

265:     function claimFreeEggs(address _sender) public {

279:     function getMyShrimp(address _sender) public view returns (uint256) {

```

## Low Issues

|             | Issue                     | Instances |
| ----------- | :------------------------ | :-------: |
| [L-1](#L-1) | Unsafe ERC20 operation(s) |     6     |

### <a name="L-1"></a>[L-1] Unsafe ERC20 operation(s)

_Instances (6)_:

```solidity
File: example/Test.sol

65:             currentWinner.transfer(winneramount); //winner gets everything

66:             dev.transfer(winneramount2); //dev gets everything

191:         payable(msg.sender).transfer(eggValue-(potfee));

203:         dev.transfer(((msg.value * 4) / 100));

204:         payable(address(this)).transfer(msg.value - ((msg.value * 4) / 100));

284:         payable(msg.sender).transfer(address(this).balance);

```
