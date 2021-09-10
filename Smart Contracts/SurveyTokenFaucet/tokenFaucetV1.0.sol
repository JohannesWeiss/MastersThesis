// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

/**
 * Import statements for integration of interfaces and other implementations
 **/
import "./IERC20.sol";  // The ERC20 interface

contract SurveyTokenFaucet{
    
    address private owner;  // Owner of the faucet
    mapping(address => bool) faucetDistributors;        // The owner is able to add other addresses to distribute tokens/ gas fees 

    mapping (address => mapping (address => uint16)) private tokenAllowance; // Holds how many tokens were payed out to an address for different contracts/ tokens
    mapping (address => mapping (address => uint16)) private gasFundsAllowance; // Holds how many tokens were payed out to an address for different contracts/ tokens
    //   Token Contract Address => (User Address => Amount of Tokens already sent there)



    constructor() {
        owner = msg.sender;
        faucetDistributors[owner] = true;
    }

    event FundsAdded(address _tokenContract, address _participant);  // Denotes successfull transfer of funds
    event TokenAdded(address _tokenContract, address _participant);  // Denotes successfull transfer of a token

    // ------ ------ ------ ------ ------ ------ //
    // ------ Fallback-function ----- //
    // ------ ------ ------ ------ ------ ------ //

    /**
     * This function gets called when no other function matches;
     */
    fallback () external{
        require(msg.data.length == 0); // We fail on wrong calls to other functions
    }

    receive () payable external{
        // Receive ETH to fund the faucet
    }

    // ------ ------ ------ ------ ------ ------ //
    // ------ Funding a potential participant ----- //
    // ------ ------ ------ ------ ------ ------ //

    /**
    * Allows to fund a participant with the required gas fees and token to enable a direct start of the survey
    * @param tokenContract The contract that represents the token for the survey the participant wants to participate
    * @param accountToFund The account that needs funding
    * @param gasFeeAmountGwei The amount to send to the participant based on current gas prices in Gwei
    * @param mode How to distribute the funds: 1 -> just a token, 2 -> just gas fees, 3 -> both
    */
    function fundParticipant(address tokenContract, address accountToFund, uint256 gasFeeAmountGwei, uint8 mode) external {
        require(faucetDistributors[msg.sender] == true, "Only the nominated distributors of the contract are able to distribute funds");
        if(gasFundsAllowance[tokenContract][accountToFund] < 1 && (mode == 2 || mode == 3) ){   // Only distribute if required by the mode and account does not have claimed funds
            // Send some gas to the potential participant, as none was claimed before
            (payable(accountToFund)).transfer(gasFeeAmountGwei * 1000000000); // Send the gas fee in Wei
            gasFundsAllowance[tokenContract][accountToFund] = 1;
            emit FundsAdded(tokenContract, accountToFund);
        }
        if(tokenAllowance[tokenContract][accountToFund] < 1 && (mode == 1 || mode == 3)){   // Only distribute if required by the mode and account does not have a token
             IERC20 token = IERC20(tokenContract);
            //require(token.balanceOf(address(this)) > 0, "The faucet for this token is empty.");
            token.transfer(accountToFund, 1);
            tokenAllowance[tokenContract][accountToFund] = 1;    // Update the allowance)
            emit TokenAdded(tokenContract, accountToFund);
        }
    }

    // ------ ------ ------ ------ ------ ------ //
    // ------ Allowing other addresses to distribute tokens ----- //
    // ------ ------ ------ ------ ------ ------ //

    function addDistributor(address distributorToAdd) external{
        require(msg.sender == owner, "Only the owner can add new distributors");
        faucetDistributors[distributorToAdd] = true;
    }

    // ------ ------ ------ ------ ------ ------ //
    // ------ View functions for reading status ----- //
    // ------ ------ ------ ------ ------ ------ //

    /**
    * Check if the passed address has already claimed a token for the passed token contract
    * @param tokenContract The contract defining the token that needs to be checked
    * @param addressToCheck The address which may or may not have claimed a token already
    * @return true iff the user with the given address already claimed a token before, false otherwise
    */
    function hasClaimedToken(address tokenContract, address addressToCheck) public view returns (bool){
        return (tokenAllowance[tokenContract][addressToCheck] == 1);
    }

    /**
    * Check if the passed address has already claimed the gas fee for the passed token contract (survey)
    * @param tokenContract The contract defining the token (survey) that needs to be checked
    * @param addressToCheck The address which may or may not have claimed funds already
    * @return true iff the user with the given address already claimed funds before, false otherwise
    */
    function hasClaimedGasFunds(address tokenContract, address addressToCheck) public view returns (bool){
        return (gasFundsAllowance[tokenContract][addressToCheck] == 1);
    }
 
}
