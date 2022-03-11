import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
require('babel-polyfill');


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
web3.eth.defaultAccount = web3.eth.accounts[0];
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let oracles = [] //List of Registered Oracles.
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);

flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log(event)
  let airline = event.returnValues[1]
  let flight = event.returnValues[2]
  let updatedTimestamp = event.returnValues[3]
  submitOracleResponse(airline, flight, updatedTimestamp)
});

// Log Updates from the contracts
flightSuretyData.events.allEvents({
  fromBlock: "latest"
}, function (error, event) {
  if (error) {
    console.log("********* ERROR *********");
    console.log(error);
    console.log("********* ERROR *********");
  } else {
    console.log("-----------  EVENT ------------:");
    console.log(event);
    console.log("-----------  EVENT ------------:");
  }
});

const ORACLES = 20

async function registerOracles() {
  let fee = await flightSuretyApp.methods.REGISTRATION_FEE().call();
  let accounts = await web3.eth.getAccounts();
  for (var i = 20; i < ORACLES + 20; i++) {
    oracles.push(accounts[i]);
    await flightSuretyApp.methods.registerOracle().send({ from: accounts[i], value: fee, gas: 5000000, gasPrice: 20000000 });
  }
}

async function submitOracleResponse(airline, flight, timestamp) {
  for (var i = 0; i < oracles.length; i++) {
    var statusCode = generateStatus();
    var indexes = await flightSuretyApp.methods.getMyIndexes().call({ from: oracles[i] });
    for (var j = 0; j < indexes.length; j++) {
      try {
        await flightSuretyApp.methods.submitOracleResponse(
          indexes[j], airline, flight, timestamp, statusCode
        ).send({ from: oracles[i], gas: 999999999 });
      } catch (e) {
        console(e)
      }
    }
  }
}

function generateStatus() {
  let code = (Math.floor(Math.random() * Math.floor(4)) + 1) * 10 + 10; // Randomly grab a sta
  return code;
}


registerOracles();

const app = express();
app.get('/api', (req, res) => {
  res.send({
    message: 'An API for use with your Dapp!'
  })
})

export default app;


