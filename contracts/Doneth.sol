pragma solidity ^0.4.15;

/**
 * @title Doneth (Don.eth)
 * @dev Doneth is a contract that allows members of a project
 * to share donations. Project supporters can submit donations.
 * The admins of the contract determine who is a member, and each
 * member gets a number of shares. The number of shares each 
 * member has determines how much Ether the member can withdraw 
 * from the contract. 
 */
contract Doneth {
    using SafeMath for uint256;  

    // Address of the contract creator
    address public founder;

    // Name of the contract
    string public name;

    // Sum of all shares allocated to members
    uint256 public totalShares;

    // Sum of all withdrawals done by members
    uint256 public totalWithdrawn;

    // Variables to be used in the future 
    bool public incrementShares;
    uint256 public incrementInterval;

    // Block number of when the contract was created
    uint256 public genesisBlockNumber;

    // Number of decimal places for floating point division
    uint256 constant public PRECISION = 18;

    // Used to keep track of members
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

    // Fallback function accepts Ether from donators
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

    // Series of getter functions for contract data
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

    function getContractInfo() constant returns(string, address, uint256, uint256, uint256) {
        return (name, founder, genesisBlockNumber, totalShares, totalWithdrawn);
    }
    
    function returnMember (address _address) constant onlyExisting(_address) returns(bool active, bool admin, uint256 shares, uint256 withdrawn, string memberName) {
      Member memory m = members[_address];
      return (m.active, m.admin, m.shares, m.withdrawn, m.memberName);
    }

    // Function to add members to the contract 
    function addMember(address who, uint256 shares, bool admin, string memberName) public onlyAdmin() {
        // Don't allow the same member to be added twice
        if (members[who].exists) revert();

        Member memory newMember;
        newMember.exists = true;
        newMember.admin = admin;
        newMember.active = true;
        newMember.memberName = memberName;

        members[who] = newMember;
        memberKeys.push(who);
        addShare(who, shares);
    }

    // Increment the number of shares for a member
    function addShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.add(amount);
        members[who].shares = members[who].shares.add(amount);
        AddShare(who, amount, members[who].shares);
    }

    // Decrement the number of shares for a member
    function removeShare(address who, uint256 amount) public onlyAdmin() onlyExisting(who) {
        totalShares = totalShares.sub(amount);
        members[who].shares = members[who].shares.sub(amount);
        RemoveShare(who, amount, members[who].shares);
    }

    // Function for a member to withdraw Ether from the contract proportional
    // to the amount of shares they have. Calculates the totalWithdrawableAmount
    // in Ether based on the member's share and the Ether balance of the contract,
    // then subtracts the amount of Ether that the member has already previously
    // withdrawn.
    function withdraw(uint256 amount) public onlyExisting(msg.sender) {
        uint256 newTotal = calculateTotalWithdrawableAmount(msg.sender);
        if (amount > newTotal.sub(members[msg.sender].withdrawn)) revert();
        
        members[msg.sender].withdrawn = members[msg.sender].withdrawn.add(amount);
        totalWithdrawn = totalWithdrawn.add(amount);
        msg.sender.transfer(amount);
        Withdraw(msg.sender, amount, totalWithdrawn);
    }

    // Converts from shares to Eth.
    // Ex: 100 shares, 1000 total shares, 100 Eth balance
    // 100 Eth / 1000 total shares = 1/10 eth per share * 100 shares = 10 Eth to cash out
    function calculateTotalWithdrawableAmount(address who) public constant onlyExisting(who) returns (uint256) {
        // Need to use parts-per notation to compute percentages for lack of floating point division
        uint256 balanceSum = this.balance.add(totalWithdrawn);
        uint256 ethPerSharePPN = balanceSum.percent(totalShares, PRECISION); 
        uint256 ethPPN = ethPerSharePPN.mul(members[who].shares);
        uint256 ethVal = ethPPN.div(10**PRECISION); 
        Division(ethVal, balanceSum, totalShares);
        return ethVal;
    }

    // Used for testing
    function delegatePercent(uint256 a, uint256 b, uint256 c) public constant returns (uint256) {
        return a.percent(b, c);
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

    // Using from SO: https://stackoverflow.com/questions/42738640/division-in-ethereum-solidity/42739843#42739843
    // Adapted to use SafeMath and uint256.
    function percent(uint256 numerator, uint256 denominator, uint256 precision) internal constant returns(uint256 quotient) {
        // caution, check safe-to-multiply here
        uint256 _numerator = mul(numerator, 10 ** (precision+1));
        // with rounding of last digit
        uint256 _quotient = (div(_numerator, denominator) + 5) / 10;
        return (_quotient);
    }
}

