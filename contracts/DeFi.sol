// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "contracts/MarginToken.sol";

contract DeFi {
    address private Owner;
    address private TokenAddress;
    uint256 public MarginRate;
    mapping(address => uint256) private _Lender;
    mapping(address => uint256[][]) private _Borrower;
    address[] _BorrowerList;
    uint256 public BorrowPeriod;


    constructor() {
        Owner = msg.sender;

    }

    function is_in(address value, address[] memory array)
        private
        pure
        returns (bool isin)
    {
        for (uint256 i; i < array.length; i++) {
            if (value == array[i]) {
                return true;
            }
        }
        return false;
    }

    function SetToken(address setTokenAddress) external {
        require(msg.sender == Owner, "Admin only");
        TokenAddress = setTokenAddress;
    }

    function SetMagin(uint256 Margin_Rate_percent) external {
        MarginRate = Margin_Rate_percent;
    }

    function SetBorrowPeriod(uint256 period_sec) public {
        BorrowPeriod = period_sec;
    }

    function deposit() external payable {
        require(msg.value > 0, "Amount invalid");
        _Lender[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount invalid");
        require(amount <= _Lender[msg.sender], "Balance not eough");
        require(
            amount <= address(this).balance,
            "Smart Contact have not enough eth"
        );
        _Lender[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Amount invalid");
        require(
            amount <= address(this).balance,
            "Smart Contact have not enough eth"
        );
        MarginToken Token = MarginToken(TokenAddress);
        Token.approve(msg.sender, address(this), (amount * MarginRate) / 100);
        Token.transferFrom(
            msg.sender,
            address(this),
            (amount * MarginRate) / 100
        );
        if (!is_in(msg.sender, _BorrowerList)) {
            _BorrowerList.push(msg.sender);
        }
        _Borrower[msg.sender].push() = [block.timestamp + BorrowPeriod, amount];
        payable(msg.sender).transfer(amount);
    }

    function repay() external payable {
        require(msg.value > 0, "Amount invalid");
        if (!is_in(msg.sender, _BorrowerList)) {
            revert("You have no dept");
        } else {
            Margin_call_Account(msg.sender);
        }
        require(msg.value <= Check_Dept(msg.sender), "Amount more than dept");
        MarginToken Token = MarginToken(TokenAddress);
        Token.transfer(msg.sender, (msg.value * MarginRate) / 100);
        DeleteRecord(msg.sender, msg.value);
    }

    function DecreaseDept(address borrower, int256 amount)
        private
        view
        returns (uint256[2] memory)
    {
        int256 index;
        for (uint256 i; amount > 0; i++) {
            index++;
            amount -= int256(_Borrower[borrower][i][1]);
        }
        return [uint256(-amount), uint256(index - 1)];
    }

    function DeleteRecord(address borrower, uint256 amount) private {
        uint256[2] memory data = DecreaseDept(borrower, int256(amount));
        for (uint256 i; i < _Borrower[borrower].length - data[1]; i++) {
            _Borrower[borrower][i] = _Borrower[borrower][i + data[1]];
        }
        for (uint256 i; i < data[1]; i++) {
            _Borrower[borrower].pop();
        }
        _Borrower[borrower][0][1] = data[0];
    }

    function Get_Free_Token(uint256 amount) external {
        MarginToken Token = MarginToken(TokenAddress);
        Token.GetToken(msg.sender, amount);
    }

    function Check_Token(address account) private view returns (uint256) {
        MarginToken Token = MarginToken(TokenAddress);
        return Token.balanceOf(account);
    }

    function Check_Dept(address account) private view returns (uint256) {
        uint256 dept;
        for (uint256 j; j < _Borrower[account].length; j++) {
            dept += _Borrower[account][j][1];
        }
        return dept;
    }

    function Check_Balance() external view returns (uint256) {
        return _Lender[msg.sender];
    }

    function Check_All_Dept() public view returns (uint256) {
        uint256 dept;
        for (uint256 i; i < _BorrowerList.length; i++) {
            for (uint256 j; j < _Borrower[_BorrowerList[i]].length; j++) {
                dept += _Borrower[_BorrowerList[i]][j][1];
            }
        }
        return dept;
    }

    function Margin_call() public {
        for (uint256 i; i < _BorrowerList.length; ) {
            if (Check_Margin(i) != 2) {
                i++;
            }
        }
    }

    function Margin_call_Account(address borrower) private  {
        for (uint256 i; i < _BorrowerList.length; i++) {
            if (_BorrowerList[i] == borrower) {
                Check_Margin(i);
                break;
            }
        }
    }

    function Check_Margin(uint256 i) private returns (uint256 result) {
        for (uint256 j; j < _Borrower[_BorrowerList[i]].length; j++) {
            if (_Borrower[_BorrowerList[i]][j][0] >= block.timestamp) {
                if (j != 0) {
                    j--;
                    for (
                        uint256 k;
                        k < _Borrower[_BorrowerList[i]].length - j;
                        k++
                    ) {
                        _Borrower[_BorrowerList[i]][k] = _Borrower[
                            _BorrowerList[i]
                        ][k + j];
                    }
                    for (uint256 k; k < j; k++) {
                        _Borrower[_BorrowerList[i]].pop();
                    }
                    return 1; //delete something
                } else {
                    return 0; //every dept is in period
                }
            } else if (
                j == _Borrower[_BorrowerList[i]].length - 1 ||
                (j == 0 && _Borrower[_BorrowerList[i]].length == 1)
            ) {
                if (_Borrower[_BorrowerList[i]].length != 1) {
                    _BorrowerList[i] = _BorrowerList[_BorrowerList.length - 1];
                }
                delete _Borrower[_BorrowerList[i]];
                _BorrowerList.pop();
                return 2; //delete everything
            }
        }
    }

    function Check_Confiscated_Token()
        external
        view
        returns (uint256 Confiscated_Token)
    {
        return Check_Token(address(this)) - ((Check_All_Dept() * MarginRate) / 100);
    }

    function Check_My_Dept() public view returns(uint){
        return Check_Dept(msg.sender);
    }

    function Check_My_Token() public view returns(uint){
        return Check_Token(msg.sender);
    }
}
