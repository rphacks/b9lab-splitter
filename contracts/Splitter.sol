pragma solidity 0.4.24;

import "./Ownable.sol";

contract Splitter is Ownable {

    struct RecipientStruct {
      uint IdListPointer;
      uint claimed;
      uint missed;
    }

    mapping (address => RecipientStruct) private recipientStructs;
    address[] private recipientIndex;

    uint amountClaimablePerRecipient;
    uint returnFunds;

    event LogAddRecipient (address indexed recipientAddress);
    event LogUpdateRecipient (address indexed oldAddress, address indexed newAddress);
    event LogRemoveRecipient (address indexed recipientAddress);
    event LogWithdraw (address indexed withdrawAddress, uint amount);

    constructor() public {
    }

    function split() onlyOwner payable public {

        uint toReturn = msg.value % recipientIndex.length;
        uint toSplit = (msg.value - toReturn) / recipientIndex.length;

        returnFunds += toReturn;
        amountClaimablePerRecipient += toSplit;
    }

    function withdrawOwnerFunds() onlyOwner public {
        require(returnFunds > 0);

        uint to_widthdraw = returnFunds;
        returnFunds = 0;

        emit LogWithdraw (msg.sender, to_widthdraw);
        msg.sender.transfer(to_widthdraw);
    }

    function withdraw() public {
        require(isRecipient(msg.sender), "The address supplied is not registered as a recipient");

        uint alreadyClaimed = recipientStructs[msg.sender].claimed;
        uint toClaim = (amountClaimablePerRecipient - alreadyClaimed) - recipientStructs[msg.sender].missed;
        require(toClaim > 0);
        recipientStructs[msg.sender].claimed = alreadyClaimed + toClaim;

        emit LogWithdraw (msg.sender, toClaim);
        msg.sender.transfer(toClaim);
    }

    function addRecipient(address recipientAddress) onlyOwner public {
        require(!isRecipient(recipientAddress), "The address supplied is already registered as a recipient - cannot be added again");

        recipientStructs[recipientAddress].missed = amountClaimablePerRecipient;
        recipientStructs[recipientAddress].claimed = 0;
        recipientStructs[recipientAddress].IdListPointer = recipientIndex.push(recipientAddress) - 1;

        emit LogAddRecipient (recipientAddress);
    }

    function updateRecipient(address oldAddress, address newAddress) onlyOwner public {
        require(isRecipient(oldAddress), "The address supplied does not match any stored recipient address");

        uint temp_claimed = recipientStructs[oldAddress].claimed;
        uint temp_missed = recipientStructs[oldAddress].missed;

        removeRecipient(oldAddress, false);
        addRecipient(newAddress);

        recipientStructs[newAddress].claimed = temp_claimed;
        recipientStructs[newAddress].missed = temp_missed;

        emit LogUpdateRecipient (oldAddress, newAddress);
    }

    function removeRecipient(address recipientAddress, bool doReturn) onlyOwner public {
        require(isRecipient(recipientAddress), "The address supplied does not match any stored recipient address");

        if(doReturn){
            returnFunds += (amountClaimablePerRecipient - recipientStructs[recipientAddress].missed) - recipientStructs[recipientAddress].missed;
        }

        uint rowToDelete = recipientStructs[recipientAddress].IdListPointer;
        address keyToMove = recipientIndex[recipientIndex.length-1];

        recipientIndex[rowToDelete] = keyToMove;
        recipientStructs[keyToMove].IdListPointer = rowToDelete;

        recipientIndex.length --;

        emit LogRemoveRecipient (recipientAddress);
    }

    function isRecipient(address recipientAddress) private view returns (bool isIndeed) {
        if(recipientIndex.length == 0) return false;
        return (recipientIndex[recipientStructs[recipientAddress].IdListPointer] == recipientAddress);
    }

    function getRecipient(address recipientAddress) public view returns(uint claimed, uint missed, uint IdListPointer){
        require(isRecipient(recipientAddress), "The address supplied does not match any stored recipient address");
        return(recipientStructs[recipientAddress].claimed, recipientStructs[recipientAddress].missed, recipientStructs[recipientAddress].IdListPointer);
    }

    function getRecipientAtIndex(uint index) public view returns(address recipientAddress){
        return recipientIndex[index];
    }

    function getRecipientCount() public view returns(uint count){
        return recipientIndex.length;
    }
}
