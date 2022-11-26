// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract test{
    mapping (address=>uint[][]) public _Borrower;
    
    function borrow(uint N) external{
        uint am;
        for (uint i; i < N; i++) 
        {
          am += 10;
          _Borrower[msg.sender].push() = [block.timestamp, am];
        }
    }

    function GetDept(address borrower) public view returns(uint){
        uint amount;
        for (uint i; i < _Borrower[borrower].length; i++) 
        {
            amount += _Borrower[borrower][i][1];
        }
        return amount;
    }

    function DecreaseDept(address borrower, int amount) private view returns(uint[2] memory){
        int index;
        for (uint i; amount > 0; i++) 
        {
            index++;
            amount -= int(_Borrower[borrower][i][1]);
        }
        return [uint(-amount), uint(index-1)];
    } 
    function DeleteRecord(address borrower, uint amount) public{
        uint[2] memory data = DecreaseDept(borrower, int(amount));
        for(uint i; i < _Borrower[borrower].length-data[1]; i++){
          _Borrower[borrower][i] = _Borrower[borrower][i+data[1]];
        }
        for (uint i; i < data[1]; i++) 
        {
            _Borrower[borrower].pop();
        }
        _Borrower[borrower][0][1] = data[0];
    }
}