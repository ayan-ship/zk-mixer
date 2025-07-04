use std::hash::poseidon2;
mod merkle_tree;

fn main(
    //Public Input 
    root: pub Field,
    nullifier_hash: pub Field,
    recipient: pub Field,

    //private inputs
    secret: Field,
    nullifier: Field,
    merkle_proof: [Field; 20],
    is_even: [bool; 20]
) {
    // compute the commitment using poseidon(secret, nullifier)
    let commitment: Field = poseidon2::Poseidon2::hash([nullifier, secret], 2);
    // check that nullifier matches the nullifier hash 
    let computed_nullifier_hash: Field = poseidon2::Poseidon2::hash([nullifier], 1);

    assert(computed_nullifier_hash == nullifier_hash);

    let computed_root: Field = merkle_tree::computed_merkle_root(commitment, merkle_proof, is_even);
    assert(computed_root==root);

    let recipient_binding: Field = (recipient*recipient);
    assert(recipient_binding==(recipient*recipient));
}