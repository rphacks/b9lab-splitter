pragma solidity 0.4.25;

import "./Ownable.sol";

contract Splitter is Ownable {
    
    address[] public recipients;
    mapping (address => uint) public balances;
    
    event LogAddRecipient (address indexed recipientAddress);
    event LogUpdateRecipient (address indexed oldAddress, address indexed newAddress);
    event LogRemoveRecipient (address indexed recipientAddress);
    event LogWithdraw (address indexed withdrawAddress, uint amount);
    
    constructor() public {
        balances[msg.sender] = 0;
    }
    
    function split() onlyOwner payable public {
        
        uint numberOfRecipients = recipients.length;
        
        uint toReturn = msg.value % numberOfRecipients;
        uint toSplit = (msg.value - toReturn) / numberOfRecipients;
        
        balances[msg.sender] += toReturn;
        
        for (uint i=0; i < numberOfRecipients; i++) {
            balances[recipients[i]] += toSplit;
        }
    }
    
    function withdraw() public {
        uint toWithdraw = balances[msg.sender];
        require(toWithdraw > 0);
        balances[msg.sender] = 0;
        msg.sender.transfer(toWithdraw);
        
        emit LogWithdraw (msg.sender, toWithdraw);
    }
    
    function addRecipient(address recipientAddress) onlyOwner public {
        (bool foundAddress, uint addressIndex) = findRecipient(recipientAddress);
        require(! foundAddress, "The address supplied is already registered as a recipient - cannot be added again");
        
        recipients.push(recipientAddress);
        balances[recipientAddress] = 0;
        
        emit LogAddRecipient (recipientAddress);
    }
    
    function updateRecipient(address oldAddress, address newAddress) onlyOwner public {
        (bool foundOldAddress, uint oldAddressIndex) = findRecipient(oldAddress);
        require(foundOldAddress, "The address supplied does not match any stored recipient address");
        
        uint tempBalance = balances[oldAddress];
        delete balances[oldAddress];
        balances[newAddress] = tempBalance;
        
        recipients[oldAddressIndex] = newAddress;
        
        emit LogUpdateRecipient (oldAddress, newAddress);
    }
    
    function removeRecipient(address recipientAddress) onlyOwner public {
        (bool foundOldAddress, uint oldAddressIndex) = findRecipient(recipientAddress);
        require(foundOldAddress, "The address supplied does not match any stored recipient address");
        
        balances[owner()] += balances[recipientAddress];
        delete balances[recipientAddress];
        
        recipients[oldAddressIndex] = recipients[recipients.length-1];
        recipients.length --;
        
        emit LogRemoveRecipient (recipientAddress);
    }
    
    function findRecipient(address recipientAddress) private view returns (bool, uint) {
        uint numberOfRecipients = recipients.length;
        bool foundOldAddress = false;
        
        for (uint i=0; i < numberOfRecipients; i++) {
            if(recipients[i] == recipientAddress) {
                foundOldAddress = true;
                break;
            }
        }
        
        return (foundOldAddress, i);
    }
}