// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;
import {IVerifier} from "./Verifier.sol";
import {IncrementalMerkleTree, Poseidon2} from "./IncrementalMerkleTree.sol";

contract Mixer is IncrementalMerkleTree{

    IVerifier public immutable i_verifier;
    uint256 public constant DENOMINATION = 0.001 ether;
    mapping(bytes32=>bool) s_commitments;
    mapping (bytes32=>bool) s_nullifierHashes;

    constructor(IVerifier _verifier,uint32 _merkleTreedepth,Poseidon2 _hasher ) IncrementalMerkleTree(_merkleTreedepth, _hasher ){
        i_verifier = _verifier;
    }

    event Deposit (bytes32 indexed commitment, uint32 insertedIndex, uint256 time);
    event Withdrawal ( address indexed recipient, bytes32 nullifierHash);

    //ERRORS
    error Mixer_CommitmentAlreadyAdded(bytes32 commitment);
    error Mixer_DepositAmountNotCorrect(uint256 amountSent, uint256 expectedAmount);
    error Mixer_UnknownRoot(bytes32 root);
    error Mixer_NullifierAlreadyUsed(bytes32 nullifierHash);
    error Mixer_InvalidProof();
    error Mixer_PaymentFailed(address recipient, uint256 amount );

    /// @notice Deposit funds into the mixer contract
    /// @param _commitment the posidon commitment of the nullifier and secret (generated off chain)
    function deposit(bytes32 _commitment) external payable{
        //check the commitment passed by the user whether it is already used or not 
        if(s_commitments[_commitment]){
            revert Mixer_CommitmentAlreadyAdded(_commitment);
        }
        // checks user deposits the 0.001 ETH to the function a fixed denomination
        if(msg.value != DENOMINATION){
            revert Mixer_DepositAmountNotCorrect(msg.value, DENOMINATION);
        }
        // store the commitment in an appropriate data structure and store the commitment in the merkle tree so that we can later verify that
        //using the proof that whether the commitmnet is in merkle tree or not
        uint32 insertedIndex= _insert(_commitment);
        s_commitments[_commitment]= true;

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }
    /// @notice check the commitment/proof in an private way 
    /// @param _proof the proof that the user has the right to withdraw
    // we cannot directly pass the commitment in the withdraw function as it would kind off defeat the purpose of the privacy 
    // because anyone would be able to check that who deposit the ether by checking who withdrew that ether with the particular commitment
    // so we use merkle tree and merkle proof with the proof associated with the proof that we provide
    function withdraw(bytes memory _proof, bytes32 _root, bytes32 _nullifierHash, address payable _recipient) external {
        // check that the root paased is the same root as the root of merkle tree on chain
        if (!isKnownRoot(_root)){
            revert Mixer_UnknownRoot(_root);
        }
        //check that the nullifier is not have been used before
        if(s_nullifierHashes[_nullifierHash]){
            revert Mixer_NullifierAlreadyUsed(_nullifierHash);
        }
        // check that the proof is valid by calling the verifier function
        bytes32[] memory  _publicInputs= new bytes32[] (3);
        _publicInputs[0] =_root;
        _publicInputs[1]=_nullifierHash;
        _publicInputs[2]=bytes32(uint256(uint160(address(_recipient))));
        if(!i_verifier.verify(_proof, _publicInputs)){
            revert Mixer_InvalidProof();
        }
        s_nullifierHashes[_nullifierHash] = true;
        
        // send the fund
        
        (bool success, ) = _recipient.call{value: DENOMINATION}("");
        if(!success){
            revert Mixer_PaymentFailed (_recipient, DENOMINATION);
        }
        emit Withdrawal (_recipient, _nullifierHash);
    }
}