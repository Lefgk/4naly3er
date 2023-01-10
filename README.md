# Report

## Gas Optimizations

|                 | Issue                                                                                        | Instances |
| --------------- | :------------------------------------------------------------------------------------------- | :-------: |
| [GAS-1](#GAS-1) | Use `selfbalance()` instead of `address(this).balance`                                       |     1     |
| [GAS-2](#GAS-2) | Use assembly to check for `address(0)`                                                       |     1     |
| [GAS-3](#GAS-3) | Cache array length outside of loop                                                           |     2     |
| [GAS-4](#GAS-4) | State variables should be cached in stack variables rather than re-reading them from storage |     2     |
| [GAS-5](#GAS-5) | Use calldata instead of memory for function arguments that do not get mutated                |     2     |
| [GAS-6](#GAS-6) | Use Custom Errors                                                                            |     2     |
| [GAS-7](#GAS-7) | Don't initialize variables with default value                                                |     6     |
| [GAS-8](#GAS-8) | `++i` costs less gas than `i++`, especially when it's used in `for`-loops (`--i`/`i--` too)  |     5     |

### <a name="GAS-1"></a>[GAS-1] Use `selfbalance()` instead of `address(this).balance`

Use assembly when getting a contract's balance of ETH.

You can use `selfbalance()` instead of `address(this).balance` when getting your contract's balance of ETH to save gas.
Additionally, you can use `balance(address)` instead of `address.balance()` when getting an external contract's balance of ETH.

_Saves 15 gas when checking internal balance, 6 for external_

_Instances (1)_:

```solidity
File: example/Test.sol

37:         payable(msg.sender).transfer(address(this).balance);

```

### <a name="GAS-2"></a>[GAS-2] Use assembly to check for `address(0)`

_Saves 6 gas per instance_

_Instances (1)_:

```solidity
File: example/Test.sol

98:          if(winners[j] != address(0)) {

```

### <a name="GAS-3"></a>[GAS-3] Cache array length outside of loop

If not cached, the solidity compiler will always read the length of the array during each iteration. That is, if it is a storage array, this is an extra sload operation (100 additional extra gas for each iteration except for the first) and if it is a memory array, this is an extra mload operation (3 additional gas for each iteration except for the first).

_Instances (2)_:

```solidity
File: example/Test.sol

49:       for(uint256 i = 0; i < playersID.length; i++){

81:        for(uint256 i = 0; i < playersID.length; i++){

```

### <a name="GAS-4"></a>[GAS-4] State variables should be cached in stack variables rather than re-reading them from storage

The instances below point to the second+ access of a state variable within a function. Caching of a state variable replaces each Gwarmaccess (100 gas) with a much cheaper stack read. Other less obvious fixes/optimizations include having local memory caches of state variable structs, or having local caches of state variable contracts/addresses.

_Saves 100 gas per instance_

_Instances (2)_:

```solidity
File: example/Test.sol

93:           totalWin = totalBetsTwo;

94:           totalLost = totalBetsOne;

```

### <a name="GAS-5"></a>[GAS-5] Use calldata instead of memory for function arguments that do not get mutated

Mark data types as `calldata` instead of `memory` where possible. This makes it so that the data is not automatically loaded into memory. If the data passed into the function does not need to be changed (like updating values in an array), it can be passed in as `calldata`. The one exception to this is if the argument must later be passed into another function that takes an argument that specifies `memory` storage.

_Instances (2)_:

```solidity
File: example/Test.sol

30:     constructor(address admin, string memory description, uint _expirationTime)  {

44:     function setWinningFighter(string memory Side) public  {

```

### <a name="GAS-6"></a>[GAS-6] Use Custom Errors

[Source](https://blog.soliditylang.org/2021/04/21/custom-errors/)
Instead of using error strings, to reduce deployment and runtime cost, you should use Custom Errors. This would save both deployment and runtime cost.

_Instances (2)_:

```solidity
File: example/Test.sol

106:         require(sent, "Failed to send Ether");

109:         require(sent, "Failed to send Ether");

```

### <a name="GAS-7"></a>[GAS-7] Don't initialize variables with default value

_Instances (6)_:

```solidity
File: example/Test.sol

49:       for(uint256 i = 0; i < playersID.length; i++){

76:        uint256 count = 0;

77:        uint256 totalWin = 0;

78:        uint256 totalLost = 0;

81:        for(uint256 i = 0; i < playersID.length; i++){

97:       for(uint256 j = 0; j < count; j++){

```

### <a name="GAS-8"></a>[GAS-8] `++i` costs less gas than `i++`, especially when it's used in `for`-loops (`--i`/`i--` too)

_Saves 5 gas per loop_

_Instances (5)_:

```solidity
File: example/Test.sol

49:       for(uint256 i = 0; i < playersID.length; i++){

61:       totalbets++;

81:        for(uint256 i = 0; i < playersID.length; i++){

85:             count++;

97:       for(uint256 j = 0; j < count; j++){

```

## Non Critical Issues

|               | Issue                                                                      | Instances |
| ------------- | :------------------------------------------------------------------------- | :-------: |
| [NC-1](#NC-1) | `require()` / `revert()` statements should have descriptive reason strings |     1     |
| [NC-2](#NC-2) | Constants should be defined rather than using magic numbers                |     1     |
| [NC-3](#NC-3) | Functions not used internally could be marked external                     |     3     |

### <a name="NC-1"></a>[NC-1] `require()` / `revert()` statements should have descriptive reason strings

_Instances (1)_:

```solidity
File: example/Test.sol

59:       require(_SideSelected==1||_SideSelected==2);

```

### <a name="NC-2"></a>[NC-2] Constants should be defined rather than using magic numbers

_Instances (1)_:

```solidity
File: example/Test.sol

103:          uint256 winnersearnings=totalwinnings*(97)/100;

```

### <a name="NC-3"></a>[NC-3] Functions not used internally could be marked external

_Instances (3)_:

```solidity
File: example/Test.sol

44:     function setWinningFighter(string memory Side) public  {

55:    function bet(uint8 _SideSelected) public payable {

73:     function distributePrizes(uint16 Fighterwinner) public {

```

## Low Issues

|             | Issue                     | Instances |
| ----------- | :------------------------ | :-------: |
| [L-1](#L-1) | Unsafe ERC20 operation(s) |     2     |

### <a name="L-1"></a>[L-1] Unsafe ERC20 operation(s)

_Instances (2)_:

```solidity
File: example/Test.sol

37:         payable(msg.sender).transfer(address(this).balance);

41:         IBRC(token).transfer(msg.sender ,amount);

```
