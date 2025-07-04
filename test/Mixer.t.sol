// SPDX-License_Identifier: MIT

pragma solidity ^0.8.24;

import {HonkVerifier} from "../src/Verifier.sol";
import {Mixer} from "../src/Mixer.sol";
import {IncrementalMerkleTree, Poseidon2} from "../src/IncrementalMerkleTree.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";

contract MixerTest is Test {
    HonkVerifier public verifier;
    Mixer public mixer;
    Poseidon2 public hasher;

    address public recipient= makeAddr("recipient");


    function setUp() public { 

        verifier = new HonkVerifier();
        hasher = new Poseidon2();
        mixer = new Mixer (verifier,20, hasher );

    }

    function _generateCommitment() public returns (bytes32, bytes32, bytes32 ) {

        //use ffi to run CLI command and generate a commitment using typescript

        string[] memory input = new string[](3);

        input[0] = "npx";
        input[1] = "tsx";
        input[2] = "js-scripts/generateCommitment.ts";

        bytes memory result= vm.ffi(input);

        //ABI decode the result 

        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = abi.decode(result, (bytes32, bytes32, bytes32));

        return (_commitment, _nullifier, _secret);


    }

    function _getProof(bytes32 _nullifier, bytes32 _secret, address _recipient, bytes32[] memory leaves) public returns(bytes memory proof ){
        // create the input to run the scripts

        string[] memory input = new string[](6+leaves.length);

        input[0] = "npx";
        input[1] = "tsx";
        input[2] = "js-scripts/generateProof.ts";
        input[3] = vm.toString(_nullifier);
        input[4] = vm.toString(_secret);
        input[5] = vm.toString(bytes32(uint256(uint160(_recipient))));

        for (uint256 i = 0; i < leaves.length; i++) {
            input[6+i] = vm.toString(leaves[i]);
        }

        bytes memory result = vm.ffi(input);

         proof = abi.decode(result, (bytes)) ; 

        return proof;

    }

    function testMakeCommitment() public {

        // make an commitment

        (bytes32 _commitment, bytes32 _nullifier, bytes32 _secret) = _generateCommitment();
        console.log("Commitment" );
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0 , block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);




    }

    function testMakeWithdraw() public{
        //make a commitment   
        
        (bytes32  _commitment, bytes32 _nullifier, bytes32 _secret)  = _generateCommitment();
        console.log("Commitment" );
        console.logBytes32(_commitment);
        vm.expectEmit(true, false, false, true);
        emit Mixer.Deposit(_commitment, 0 , block.timestamp);
        mixer.deposit{value: mixer.DENOMINATION()}(_commitment);

        //get proof for that commitment
        // till now we have only generated a commitment and made a merkle tree 
        //but now we also need to make the proof using that commitment in order to withdraw 
        // for proof we need merkle tree proof as well which we will get using the events we have emitted
        bytes32[] memory leaves = new bytes32[](1);
        leaves[0] = _commitment;
        bytes memory _proof = _getProof(_nullifier, _secret, recipient, leaves );


        //withdraw the amount
    }


}