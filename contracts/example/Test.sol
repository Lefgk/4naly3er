// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IBRC {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract Bet is Ownable {
   string public titleofBet;
   string public gameWinner;
   uint public expirationTime;
   uint256 public minimum;
   uint256 public totalbets;
   uint256 public totalBetsOne;
   uint256 public totalBetsTwo;
   address [] public playersID;
  
   struct Player {
      uint256 amt;
      uint16 SideSelected;
   }
    
   mapping(address => Player) public playerInfo;

    constructor(address admin, string memory description, uint _expirationTime)  {
      expirationTime=_expirationTime;
      titleofBet=description;
      transferOwnership(admin);
    }

    function getAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawToken(uint256 amount , address token) external {
        IBRC(token).transfer(owner() ,amount);
    }
   
    function setWinningFighter(string memory Side) external onlyOwner {
      gameWinner = Side;
    }

   function checkPlayer(address player) public view returns(bool){
       uint256 _length=playersID.length;
      for(uint256 i ; i < _length; ){
         if(playersID[i] == player) return true;
         unchecked {
            ++i;
        }
    }
      return false;
    }
   
   function bet(uint8 _SideSelected) external payable {
      require(!checkPlayer(msg.sender),'betted already');
      require(msg.value >= minimum,'value below minimum');
      require(block.timestamp >= expirationTime,'bet ended');
      require(_SideSelected==1||_SideSelected==2,'wrong side');

      ++totalbets;
      playerInfo[msg.sender].amt = msg.value;
      playerInfo[msg.sender].SideSelected = _SideSelected;
      playersID.push(msg.sender);
      
      if (_SideSelected == 1){
          totalBetsOne += msg.value;
      } else {
          totalBetsTwo += msg.value;
      } 
    }
    
    function distributePrizes(uint16 Fighterwinner) external onlyOwner{
    
       address [1000] memory winners;
       uint256 count ;
       uint256 totalWin ;
       uint256 totalLost;
       address playerAddress;
       uint256 _length=playersID.length;
       for(uint256 i; i < _length; ){
         playerAddress = playersID[i];
         if(playerInfo[playerAddress].SideSelected==Fighterwinner){
            winners[count] = playerAddress;
            ++count;
               unchecked {
            ++i;
        }

         }
      }
      
      if ( Fighterwinner == 1 ){
         totalWin = totalBetsOne;
         totalLost = totalBetsTwo;
      } else {
          totalWin = totalBetsTwo;
          totalLost = totalBetsOne;
      }
      
      for(uint256 j ; j < count;){
         if(winners[j] != address(0)) {
         
         address payable winner = payable(winners[j]);
         uint256 bett = playerInfo[winner].amt;
         uint256 totalwinnings=(bett+(bett/totalWin*(totalLost)));
         uint256 winnersearnings = (totalwinnings*97)/100;
         uint256 fee = totalwinnings-winnersearnings;
        (bool sent, bytes memory data) = winners[j].call{value: winnersearnings}("");
        require(sent, "Failed to send Ether");
    
        ( sent,  data) = owner().call{value: fee}("");
        require(sent, "Failed to send Ether");
         // owner.transfer(fee);
        }

        unchecked {
            ++j;
        }
      }
      
      delete playerInfo[playerAddress];
      delete gameWinner;
         
    }

}