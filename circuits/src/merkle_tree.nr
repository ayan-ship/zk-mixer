use std::hash::poseidon2;

pub fn computed_merkle_root(
    leaf: Field,
    merkle_proof: [Field; 20],
    is_even: [bool; 20]
)-> Field{
    // mutable variable to store the has of the current level

    let mut hash: Field = leaf;
    let mut left:Field= hash;
    let mut right: Field = hash;
    // increment through the levels
    for i in 0 ..20 {

         if is_even[i]{
            left = hash;
            right = merkle_proof[i];
        }
        else{
             left = merkle_proof[i];
            right = hash;
        }

        hash = poseidon2::Poseidon2::hash([left,right], 2);
        
    }
    // return the root of the merkle_tree
    hash 

}
