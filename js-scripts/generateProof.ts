
import { Barretenberg, Fr, UltraHonkBackend } from "@aztec/bb.js";
import {Noir} from "@noir-lang/noir_js";
import { AbiCoder, ethers } from "ethers";

import fs from "fs";
import path from "path";
import { merkleTree } from "./merkleTree.js";



const circuit = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../../circuits/target/circuits.json") , "utf8"));

export default async function generateProof (){
    
    const bb = await Barretenberg.new();
    const inputs =  process.argv.slice(2)
    const nullifier = Fr.fromString(inputs[0]);
    const secret = Fr.fromString(inputs[1]);
    const recipient = inputs[2];
    const nullifier_hash = await bb.poseidon2Hash([nullifier])
    const commitment = await bb.poseidon2Hash([nullifier, secret])
    const leafStrings = inputs.slice(3);
    const leaves = leafStrings.map(leaf => Fr.fromString(leaf));
    const tree = await merkleTree(leaves);
    const merkleProof = tree.proof(tree.getIndex(commitment.toString()))
    try{
        
        const noir = new Noir(circuit);
        const honk = new UltraHonkBackend(circuit.bytecode, {threads: 1});

        
        
        const input = {
            //public
            // recipient , nullifier hash, root
            root:merkleProof.root.toString(),
            nullifier_hash: nullifier_hash.toString(),
            recipient: recipient,
            //private
            //nullifier, secret, merkle proof, is_even
            nullifier: nullifier.toString(),
            secret:secret.toString(),
            merkle_proof: merkleProof.pathElements.map(i=>i.toString()),
            is_even:merkleProof.pathIndices.map(i=> i%2 ==0)

        }
        const { witness } = await noir.execute(input);
        const orignalLog = console.log;
        console.log = ()=>{};
        const { proof } = await honk.generateProof(witness, {keccak:true})
        console.log = orignalLog;
        const result = ethers.AbiCoder.defaultAbiCoder().encode(
            ["bytes"],
            [proof]
        )
        return result;
    }catch(error){
        console.log(error);
        throw error;
    }
}

(async ()=>{
     generateProof()
    .then((result)=>{
        process.stdout.write(result);
        process.exit(0);
    })
    .catch((error)=>{
        console.error(error);
        process.exit(1);
    })
})();