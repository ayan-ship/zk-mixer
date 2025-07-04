# ZK Mixer Project 

deposit : user can deposit some ETH into mixer to break the connection between depositer and withdrawer

withdraw: user can withdraw using a zk-proof (Noir, generated off-chain) of knowledge of their deposit

## Proof 

-we need to check that the commitment is present in our merkle tree
    -proposed root (public)
    -merkle proof
- Check that the nullifier matches the (public)nullifier hash