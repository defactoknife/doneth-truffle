var Doneth = artifacts.require("Doneth");

contract('Doneth', function(accounts) {
    let doneth;

    beforeEach(async function() { 
        doneth = await Doneth.new("test_name", "Ray Kroc");
    });
    
    describe("contract initial state tests", function() {
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
            assert.equal(founderMember[0], true); // active
            assert.equal(founderMember[1], true); // admin
            assert.equal(founderMember[2], 1); // shares
            assert.equal(founderMember[3], 0); // withdrawn
            assert.equal(founderMember[4], 'Ray Kroc'); // memberName
        });
    });

    describe("modify contract state cases", function() {
        it("should add member Maurice with 100 shares", async function() {
            await doneth.addMember(accounts[1], 100, false, "Maurice McDonald");
            const newMember = await doneth.returnMember(accounts[1]);
            assert.equal(newMember[0], true); // active
            assert.equal(newMember[1], false); // admin
            assert.equal(newMember[2], 100); // shares
            assert.equal(newMember[3], 0); // withdrawn
            assert.equal(newMember[4], 'Maurice McDonald'); // memberName
        });

        it("should remove 50 shares from Maurice", async function() {
            await doneth.addMember(accounts[1], 100, false, "Maurice McDonald");
            await doneth.removeShare(accounts[1], 50);
            const newMember = await doneth.returnMember(accounts[1]);
            assert.equal(newMember[0], true); // active
            assert.equal(newMember[1], false); // admin
            assert.equal(newMember[2], 50); // shares
            assert.equal(newMember[3], 0); // withdrawn
            assert.equal(newMember[4], 'Maurice McDonald'); // memberName
        });
    });

    describe("test send Eth and withdraw flow", function() {
        it("should send 100 Eth, add shares so that two accounts have 25 shares and 75 shares respectively, and withdraw 25 should retrieve 25 Eth for second account", async function() {
            await doneth.addShare(web3.eth.coinbase, 24);
            await doneth.addMember(accounts[1], 75, false, "Maurice McDonald");
            web3.eth.sendTransaction({from: web3.eth.coinbase, to: doneth.address, value: 100});
            assert.equal(web3.eth.getBalance(doneth.address), 100);




            const owedOld = await doneth.amountOwed(accounts[1]);
            console.log("owedOld: " + owedOld);



            await doneth.withdraw(25, {from: accounts[1]})
                .then((resp, error) => { 
                    // Testing Withdraw event
                    assert.equal(accounts[1], resp.logs[0].args["from"]);
                    assert.equal("25", resp.logs[0].args["value"]);
                });

            console.log(web3.eth.getBalance(doneth.address));

            const newMember = await doneth.returnMember(accounts[1]);
            console.log(newMember);
            assert.equal(newMember[0], true); // active
            assert.equal(newMember[1], false); // admin
            assert.equal(newMember[2], 75); // shares
            assert.equal(newMember[3], 25); // withdrawn
            assert.equal(newMember[4], 'Maurice McDonald'); // memberName

            const owed = await doneth.amountOwed(accounts[1]);
            console.log("owedNew: " + owed);
            console.log(await doneth.totalShares());

            const genesisBlockNumber = await doneth.genesisBlockNumber();
            console.log(genesisBlockNumber);

        });
    });
});
