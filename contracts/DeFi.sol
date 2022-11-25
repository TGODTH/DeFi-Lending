// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "contracts/MarginToken.sol";

contract DeFi{
    address public owner;
    address public TokenAddress;
    uint public MarginRate;
    mapping (address=>uint) public  _Lender;
    mapping (address=>uint[][]) public _Borrower;
    mapping (address=>uint) public  _BorrowerAmount;

    constructor(){
        owner = msg.sender;
    }

    function SetToken(address setTokenAddress) external{
        require(msg.sender == owner, "Admin only");
        TokenAddress = setTokenAddress;
    }

    function SetMagin(uint MarginMutiply) external{
        require(msg.sender == owner, "Admin only");
        MarginRate = MarginMutiply;
    }

    function deposit() external payable{
        _Lender[msg.sender] += msg.value;
    }
    function withdraw(uint amount) external{
        require(amount<=_Lender[msg.sender], "Balance not eough");
        _Lender[msg.sender] -= amount;
        payable (msg.sender).transfer(amount);
    }
    function borrow(uint amount) external{
        require(amount > 0, "Amount invalid");
        MarginToken Token = MarginToken(TokenAddress);
        Token.approved(msg.sender, address(this), (amount*MarginRate)/100);
        Token.transferFrom(msg.sender, address(this), (amount*MarginRate)/100);
        _Borrower[msg.sender].push() = [block.timestamp,amount];
        _BorrowerAmount[msg.sender] += amount;
        payable (msg.sender).transfer(amount);
    }

    function repay() external payable{
        require(msg.value<=_BorrowerAmount[msg.sender], "Amount more than dept");
        MarginToken Token = MarginToken(TokenAddress);
        Token.transfer(msg.sender, (msg.value*MarginRate)/100);
        DeleteRecord(msg.sender, msg.value);
        _BorrowerAmount[msg.sender] -= msg.value;
    }

    function DecreaseDept(address borrower, int amount) private view returns(int[2] memory){
        int index;
        for (uint i; amount > 0; i++) 
        {
            index++;
            amount -= int(_Borrower[borrower][i][1]);
        }
        return [amount, index-1];
    } 
    function DeleteRecord(address borrower, uint amount) public{
        int[2] memory data = DecreaseDept(borrower, int(amount));
        for(uint i; i < _Borrower[borrower].length-1; i++){
          _Borrower[borrower][i] = _Borrower[borrower][i+uint(data[1])];
        }
        for (uint i; i <= uint(data[1]); i++) 
        {
            _Borrower[borrower].pop();
        }
        _Borrower[borrower][0][1] -= uint(data[0]*2);
  }

    function GetFreeToken(uint amount) external {
        MarginToken Token = MarginToken(TokenAddress);
        Token.GetToken(msg.sender,amount);
    }

    function CheckToken() external view returns(uint){
        MarginToken Token = MarginToken(TokenAddress);
        return Token.balanceOf(msg.sender);
    }

    function CheckDept() external view returns(uint){
        return _BorrowerAmount[msg.sender];
    }

    function CheckBalance() external view returns(uint){
        return _Lender[msg.sender];
    }
}
