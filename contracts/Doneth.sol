pragma solidity ^0.4.15;

contract Doneth {
    using SafeMath for uint256;  

    address public founder;
    string public name;
    uint256 public totalShares;
    uint256 public totalWithdrawn;
    bool public incrementShares;
    uint256 public incrementInterval;
    uint256 public genesisBlockNumber;
    uint256 constant public PRECISION = 3;

    mapping(address => Member) public members;
    address[] public memberKeys;

    struct Member {
        bool exists;
        bool active;
        bool admin;
        uint256 shares;
        uint256 withdrawn;
        string memberName;
    }

    function Doneth(string _contractName, string _founderName) {
        name = _contractName;
        founder = msg.sender;
        genesisBlockNumber = block.number;
        addMember(msg.sender, 1, true, _founderName);
    }

    event Deposit(address from, uint value);
    event Withdraw(address from, uint value, uint256 newTotalWithdrawn);
    event AddShare(address who, uint256 addedShares, uint256 newTotalShares);
    event RemoveShare(address who, uint256 removedShares, uint256 newTotalShares);

    event Division(uint256 num, uint256 balance, uint256 shares);

    function () public payable {
        Deposit(msg.sender, msg.value);
    }

    modifier onlyAdmin() { 
        if (msg.sender != founder && !members[msg.sender].admin) revert();   
        _;
    }

    modifier onlyExisting(address who) { 
        if (!members[who].exists) revert(); 
        _;
    }

    function getMemberCount() constant returns(uint){
      return memberKeys.length;
    }
    
    function getMemberAtKey (uint key) constant returns(address) {
      return memberKeys[key];
    }
    
    function getBalance() constant returns(uint256 balance) {
      return this.balance;
    }
    
    function getFounder() constant returns(address) {
      return founder;
    }

    function getContractInfo() constant returns(string, address, uint256) {
        return (name, founder, genesisBlockNumber);
    }
    
    function returnMember (address _address) constant onlyExisting(_address) returns(bool active, bool admin, uint256 shares, uint256 withdrawn, string memberName) {
      Member memory m = members[_address];
      return (m.active, m.admin, m.shares, m.withdrawn, m.memberName);
    }

    function addMember(address who, uint256 shares, bool admin, string founderName) public onlyAdmin() {
        Member memory newMember;
        newMember.exists = true;
        newMember.admin = admin;
        newMember.active = true;
        newMember.memberName = founderName;
        members[who] = newMember;
        memberKeys.push(who);
        addShare(who, shares);
    }

    function addShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.add(amount);
        members[who].shares = members[who].shares.add(amount);
        AddShare(who, amount, members[who].shares);
    }

    function removeShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.sub(amount);
        members[who].shares = members[who].shares.sub(amount);
        RemoveShare(who, amount, members[who].shares);
    }

    function withdraw(uint256 amount) public onlyExisting(msg.sender) {
        uint256 newTotal = calculateTotalWithdrawableAmount(msg.sender);
        if (amount > newTotal.sub(members[msg.sender].withdrawn)) revert();
        members[msg.sender].withdrawn = members[msg.sender].withdrawn.add(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        msg.sender.transfer(amount);
        Withdraw(msg.sender, amount, totalWithdrawn);
    }

    // Converting from shares to Eth
    // 100 shares, 1000 total shares 
    // 100 Eth / 1000 total shares = 1/10 eth per share * 100 shares = 10 Eth to cash out
    function calculateTotalWithdrawableAmount(address who) public constant onlyExisting(who) returns (uint256) {
        // Need to use parts-per notation to compute percentages for lack of floating point division
        uint256 balanceSum = this.balance.add(totalWithdrawn);
        uint256 ethPerSharePPN = balanceSum.percent(totalShares, PRECISION); 
        Division(ethPerSharePPN, balanceSum, totalShares);
        uint256 ethPPN = ethPerSharePPN.mul(members[who].shares);
        Division(ethPPN, balanceSum, totalShares);
        uint256 ethVal = ethPPN.div(10**PRECISION); 
        Division(ethVal, balanceSum, totalShares);
        return ethVal;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    event Percent(uint256 retval);
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    // Using from SO: https://stackoverflow.com/questions/42738640/division-in-ethereum-solidity/42739843#42739843
    // Adapted to use SafeMath and uint256
    function percent(uint256 numerator, uint256 denominator, uint256 precision) internal constant returns(uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator  = mul(numerator, 10 ** (precision+1));
        // with rounding of last digit
        uint256 _quotient = (div(_numerator, denominator) + 5) / 10;
        return ( _quotient);
    }
}

