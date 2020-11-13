
pragma solidity 0.6.6;

import "https://raw.githubusercontent.com/smartcontractkit/chainlink/master/evm-contracts/src/v0.6/VRFConsumerBase.sol";

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract RandomNumberConsumer is VRFConsumerBase, owned {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public currentDate;
    mapping (uint => uint) public randomNumberMap;
    
    event newRandomNumber_uint(uint randomNumber);
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * 
     * Network: Mainnet
     * KeyHash: 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     * Coordinator: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * Fee: 2000000000000000000

     */
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771af9ca656af840dff83e8264ecf986ca  // LINK Token
        ) public
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 2 LINK for mainnet
    }
    
    /** 
     * Requests randomness from a user-provided seed
     */
    function generateN(uint256 userProvidedSeed) public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        require(randomNumberMap[userProvidedSeed]==0, "Already generated random number");
        currentDate = userProvidedSeed;
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint n1 = uint(keccak256(abi.encode(randomness))) % 10000;
        uint n2 = (uint(keccak256(abi.encode(randomness)))+now) % 20;
        uint finalNumber = n1 * 100 + n2;
        randomNumberMap[currentDate] = finalNumber;
        emit newRandomNumber_uint(finalNumber);
    }
    
    /**
     * Withdraw LINK from this contract
     * 
     * DO NOT USE THIS IN PRODUCTION AS IT CAN BE CALLED BY ANY ADDRESS.
     * THIS IS PURELY FOR EXAMPLE PURPOSES.
     */
    function withdrawLink() external onlyOwner{
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}
