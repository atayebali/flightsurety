pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address public firstAirline;
    address private contractOwner; // Account used to deploy contract
    bool public operational = true; // Blocks all state changes throughout the contract if false

    struct Airline {
        bool isRegistered;
        bool isFunded;
        uint256 funds;
    }

    mapping(address => Airline) airlines;
    mapping(address => uint256) private authorizedCallers;

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/
    event AirlineReg(bool, bool, uint256);

    /**
     * @dev Constructor
     *      The deploying account becomes contractOwner
     */
    constructor(address airline) public {
        firstAirline = airline;
        airlines[airline] = Airline(true, false, 0);
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

    modifier requireAuthorizedCaller() {
        require(
            authorizedCallers[msg.sender] == 1,
            "Not from an authorized caller"
        );
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

    /**
     * @dev Add an airline to the registration queue
     *      Can only be called from FlightSuretyApp contract
     *
     */
    function registerAirline(address newAirlineAddress) requireIsOperational {
        airlines[newAirlineAddress] = Airline(true, true, 0);
        emit AirlineReg(airlines[newAirlineAddress].isRegistered, true, 0);
    }

    function isAirlineRegistered(address newAirlineAddress)
        external
        returns (bool)
    {
        return airlines[newAirlineAddress].isRegistered;
    }

    /**
     * @dev Buy insurance for a flight
     *
     */
    function buy() external payable requireIsOperational {}

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
    function fund() public payable requireIsOperational {}

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
