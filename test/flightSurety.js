
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {
    var config;
    before('setup contract', async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);

    });
    describe("Operations", async () => {

        /****************************************************************************************/
        /* Operations and Settings                                                              */
        /****************************************************************************************/

        it(`(multiparty) has correct initial isOperational() value`, async function () {

            // Get operating status
            let status = await config.flightSuretyData.isOperational.call();
            assert.equal(status, true, "Incorrect initial operating status value");

        });

        it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

            // Ensure that access is denied for non-Contract Owner account
            let accessDenied = false;
            try {
                await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
            }
            catch (e) {
                accessDenied = true;
            }
            assert.equal(accessDenied, true, "Access not restricted to Contract Owner");

        });

        it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

            // Ensure that access is allowed for Contract Owner account
            let accessDenied = false;
            try {
                await config.flightSuretyData.setOperatingStatus(false);
            }
            catch (e) {
                accessDenied = true;
            }
            assert.equal(accessDenied, false, "Access not restricted to Contract Owner");

        });

        it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

            await config.flightSuretyData.setOperatingStatus(false);

            let reverted = false;
            try {
                await config.flightSurety.setTestingMode(true);
            }
            catch (e) {
                reverted = true;
            }
            assert.equal(reverted, true, "Access not blocked for requireIsOperational");

            // Set it back for other tests to work
            await config.flightSuretyData.setOperatingStatus(true);

        });
    })


    describe("Airline", async () => {
        it('cannot register an Airline using registerAirline() if it is not funded', async () => {

            // ARRANGE
            let newAirline = accounts[8];

            // ACT
            try {
                await config.flightSuretyApp.registerAirline(newAirline, { from: config.firstAirline });
            }
            catch (e) {

            }
            let result = await config.flightSuretyApp.isAirlineRegistered.call(newAirline);

            // ASSERT
            assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");
        });

        describe('Funded Airline', async () => {
            before('setup funds', async () => {
                let funds = await config.flightSuretyData.MIN_FUNDS.call();
                await config.flightSuretyData.fund({ from: config.firstAirline, value: funds });
            })

            it("only registered airline can register another up to 4 count", async () => {
                for (i = 2; i <= 6; i++) {
                    let newAirline = accounts[i];
                    await config.flightSuretyApp.registerAirline(newAirline, { from: config.firstAirline });
                    let result = await config.flightSuretyApp.isAirlineRegistered.call(newAirline);
                    //ASSERT
                    assert.equal(result, true, "The airline did not register correctly");
                }
            })
            it("Adding more than 4 airlines fails", async () => {
                let newAirline = accounts[7];
                await config.flightSuretyApp.registerAirline(newAirline, { from: config.firstAirline });
                let result = await config.flightSuretyApp.isAirlineRegistered.call(newAirline);
                // ASSERT
                assert.equal(result, false, "Airline got added and it should not have.");
            })
        })
    })




});
