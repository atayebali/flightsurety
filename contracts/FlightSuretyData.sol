pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address public firstAirline; //holds the first airline
    address private contractOwner; // Account used to deploy contract
    bool public operational = true; // Blocks all state changes throughout the contract if false

    struct Airline {
        bool isRegistered;
        bool isFunded;
        uint256 funds;
    }

    uint256 CONSENSUS_LIMIT = 4; //first 4 registered without voting
    uint256 consensus_counter = 0; // tracks registered airlines

    uint256 public constant MIN_FUNDS = 10 ether; //need for funding

    mapping(address => Airline) airlines;
    mapping(address => uint256) private authorizedCallers;

    mapping(address => address[]) private votingRecord; //tracks airline votes by new airline

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        address airline;
    }

    mapping(bytes32 => Flight) private flights;

    //Insurance per passenger
    struct Insurance {
        address passenger;
        uint256 amount;
        uint256 credit;
        uint256 payout;
    }

    // Flight Insurance. Collection of passengers with insurance by Flight
    mapping(bytes32 => Insurance) public flightInsurance;

    uint256 public constant INSURANCE_PRICE = 1 ether; // min purchase for flight insurance

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event FlightRegistered(bytes32 key);
    event InsurancePurchase(bytes32 key, address passenger);

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address airline) public {
        firstAirline = airline;
        airlines[airline] = Airline({
            isRegistered: true,
            isFunded: false,
            funds: 0
        });
        votingRecord[airline].push(msg.sender); //updating for consistency

        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
     * @dev Modifier that requires the "operational" boolean variable to be "true"
     *      This is used on all state changing functions to pause the contract in
     *      the event there is an issue that needs to be fixed
     */
    modifier requireIsOperational() {
        require(operational, "Contract is currently not operational");
        _; // All modifiers require an "_" which indicates where the function body will be added
    }
    /**
     * @dev Modifier that requires the "ContractOwner" account to be the function caller
     */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireAirlineRegistered(address addr) {
        require(airlines[addr].isRegistered, "Airline is not registered");
        _;
    }

    modifier requireAuthorizedCaller() {
        require(
            authorizedCallers[msg.sender] == 1,
            "Not from an authorized caller"
        );
        _;
    }

    modifier requireAirlineFunded(address airline) {
        require(hasFunds(airline), "Airline is not funded");
        _;
    }

    modifier requireFlightUnRegistered(bytes32 key) {
        require(!flights[key].isRegistered, "Flight is already registered");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
     * @dev Get operating status of contract
     *
     * @return A bool that is the current operating status
     */
    function isOperational() public view returns (bool) {
        return operational;
    }

    /**
     * @dev Sets contract operations on/off
     *
     * When operational mode is disabled, all write transactions except for this one will fail
     */
    function setOperatingStatus(bool mode) external requireContractOwner {
        operational = mode;
    }

    function authorizeCaller(address addr) external requireContractOwner {
        authorizedCallers[addr] = 1;
    }

    function deauthorizeCaller(address addr) external requireContractOwner {
        delete authorizedCallers[addr];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function getFirstAirline() external returns (address) {
        return firstAirline;
    }

    function getConsensusCounter() external returns (uint256) {
        return consensus_counter;
    }

    function getConsensusThreshold() external returns (uint256) {
        return CONSENSUS_LIMIT;
    }

    function hasFunds(address airline) public view returns (bool) {
        return (airlines[airline].funds >= MIN_FUNDS);
    }

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address newAirlineAddress)
        external
        requireIsOperational
        requireAuthorizedCaller
    {
        airlines[newAirlineAddress] = Airline({
            isRegistered: true,
            isFunded: false,
            funds: 0
        });
        consensus_counter = consensus_counter.add(1);
    }

    function multiPartyConsenus(address airline, address voter) returns (bool) {
        bool isDuplicate = false;

        //checking of duplicate votes and throw exception
        for (uint256 c = 0; c < votingRecord[airline].length; c++) {
            if (votingRecord[airline][c] == voter) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Airline has already voted");

        //add vote to the record and signal if ready for registration or not
        votingRecord[airline].push(msg.sender);
        if (votingRecord[airline].length >= consensus_counter.div(2)) {
            return true;
        } else {
            return false;
        }
    }

    function isAirlineRegistered(address airline) public view returns (bool) {
        return airlines[airline].isRegistered;
    }

    function isAirlineFunded(address airline) public view returns (bool) {
        return airlines[airline].isFunded;
    }

    function registerFlight(
        bytes32 key,
        address airline,
        uint256 updatedTimestamp,
        string number
    )
        external
        requireIsOperational
        requireAirlineFunded(airline)
        requireFlightUnRegistered(key)
        returns (bool)
    {
        flights[key] = Flight({
            isRegistered: true,
            statusCode: 0,
            updatedTimestamp: updatedTimestamp,
            airline: airline
        });
        emit FlightRegistered(key);
        return flights[key].isRegistered;
    }

    function isFlightRegistered(bytes32 key)
        external
        requireIsOperational
        returns (bool)
    {
        return flights[key].isRegistered;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy(
        bytes32 key,
        address passenger,
        uint256 amount
    ) external payable requireIsOperational {
        flightInsurance[key] = Insurance({
            passenger: passenger,
            amount: amount,
            payout: INSURANCE_PRICE,
            credit: 0
        });
        emit InsurancePurchase(key, passenger);
    }

    /**
     *  @dev Credits payouts to insurees
     */
    function creditInsurees() external requireIsOperational {}

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
     */
    function pay() external requireIsOperational {}

    /**
     * @dev Initial funding for the insurance. Unless there are too many delayed flights
     *      resulting in insurance payouts, the contract should be self-sustaining
     *
     */
    function fund()
        public
        payable
        requireIsOperational
        requireAirlineRegistered(msg.sender)
    {
        require(msg.value > 0, "Trying to send a bad value");
        //save the current balance
        uint256 current_balance = airlines[msg.sender].funds;
        //safe add the new value
        uint256 new_balance = current_balance.add(msg.value);
        //update balance given the add works
        airlines[msg.sender].funds = new_balance;
        airlines[msg.sender].isFunded = true;
    }

    function getFlightKey(
        address airline,
        string memory flight,
        uint256 timestamp
    ) internal requireIsOperational returns (bytes32) {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
     * @dev Fallback function for funding smart contract.
     *
     */
    function() external payable requireIsOperational {
        fund();
    }
}
