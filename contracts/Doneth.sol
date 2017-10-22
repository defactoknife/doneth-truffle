pragma solidity ^0.4.15;

contract Doneth {
    using SafeMath for uint256;  

    address public founder;
    string public name;
    uint256 public totalShares;
    bool public incrementShares;
    uint256 public incrementInterval;
    uint256 public genesisBlockNumber;

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
    event Withdraw(address from, uint value);
    event AddShare(address who, uint256 addedShares, uint256 newTotalShares);
    event RemoveShare(address who, uint256 removedShares, uint256 newTotalShares);

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
    
    function returnMember (address _address) constant  onlyExisting(_address) returns(bool active, bool admin, uint256 shares, uint256 withdrawn, string memberName) {
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
        uint256 owed = amountOwed(msg.sender);
        if (amount > owed.sub(members[msg.sender].withdrawn)) revert();
        members[msg.sender].withdrawn = members[msg.sender].withdrawn.add(amount);
        msg.sender.transfer(amount);
        Withdraw(msg.sender, amount);
    }

    // Converting from shares to Eth
    // 100 shares, 1000 total shares 
    // 100 Eth / 1000 total shares = 1/10 eth per share * 100 shares = 10 Eth to cash out
    function amountOwed(address who) public constant onlyExisting(who) returns (uint256) {
        uint256 ethPerShare = this.balance.div(totalShares); 
        return ethPerShare.mul(members[who].shares);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
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
}
