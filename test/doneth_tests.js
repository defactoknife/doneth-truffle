var Doneth = artifacts.require("Doneth");

contract('Doneth', function(accounts) {
    let doneth;

    beforeEach(async function() { 
        doneth = await Doneth.new("test_name", "Ray Kroc");
    });
    
    it("should have the name 'test_name'", async function() {
        const name = await doneth.name();
        assert.equal(name, "test_name");
    });

    it("should have founder member at the beginning", async function() {
        const count = await doneth.getMemberCount();
        assert.equal(count, 1);

        const retrieveMember = await doneth.getMemberAtKey(0);
        assert.equal(retrieveMember, web3.eth.coinbase); 

        const founder = await doneth.getFounder();
        assert.equal(founder, web3.eth.coinbase); 
    });

    it("should have 0 initial balance", async function() {
        const initialBalance = await doneth.getBalance();
        assert.equal(initialBalance, 0);
    });

    it("should have proper member fields for founder", async function() {
        const founderMember = await doneth.returnMember(web3.eth.coinbase);
        console.log(founderMember);
        assert.equal(founderMember[0], true); // active
        assert.equal(founderMember[1], true); // admin
        assert.equal(founderMember[2], 1); // shares
        assert.equal(founderMember[3], 0); // withdrawn
        assert.equal(founderMember[4], 'Ray Kroc'); // memberName
    });

});
