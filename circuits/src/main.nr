use std::hash::poseidon::bn254::hash_2 as poseidon2;
use std::hash::poseidon::bn254::hash_1 as poseidon1;

// Maximum depth of the Merkle Tree.
pub global MAX_DEPTH: u32 = 10;

// Replicate Solidity's Merkle Tree algorithm (left/right by indices bit)
fn compute_merkle_root(
    leaf: Field,
    proof_length: u32,
    proof_indices: [u1; MAX_DEPTH],
    proof_siblings: [Field; MAX_DEPTH]
) -> Field {
    let mut current_hash = leaf;

    // safety: proof_length <= MAX_DEPTH (enforce)
    assert(proof_length <= MAX_DEPTH);

    for i in 0..MAX_DEPTH {
        if i < proof_length {
            let sibling = proof_siblings[i];
            if proof_indices[i] == 0 {
                // current is left child
                current_hash = poseidon2([current_hash, sibling]);
            } else {
                // current is right child
                current_hash = poseidon2([sibling, current_hash]);
            }
        }
    }
    current_hash
}

fn main(
    // ---------- private inputs ----------
    nullifier: Field,
    secret: Field,
    merkle_proof_length: u32,
    merkle_proof_indices: [u1; MAX_DEPTH],
    merkle_proof_siblings: [Field; MAX_DEPTH],

    // ---------- public inputs ----------
    expected_merkle_root: pub Field,
    expected_nullifier_hash: pub Field,
) -> pub (Field, Field) {
    // leaf/commitment = Poseidon(nullifier, secret)
    let leaf = poseidon2([nullifier, secret]);

    let computed_nullifier_hash = poseidon1([nullifier]);
    assert(expected_nullifier_hash == computed_nullifier_hash);

    let merkle_root = compute_merkle_root(
        leaf,
        merkle_proof_length,
        merkle_proof_indices,
        merkle_proof_siblings,
    );
    assert(merkle_root == expected_merkle_root);

    (leaf, merkle_root)
}


#[test]
fn membership_with_nullifier_hash() {
    let nullifier = 123456789;
    let secret    = 987654321;

    let proof_len = 1;
    let indices   = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; 

    let sibling0 = 42;

    let siblings = [
        sibling0,
        0,0,0,0,0,0,0,0,0
    ];

    // Calculamos localmente lo que debe ser el root
    let leaf = poseidon2([nullifier, secret]);
    let expected_root = poseidon2([leaf, sibling0]);
    let expected_nullifier_hash = poseidon1([nullifier]);

    // Llamamos main con esos datos
    let (out_leaf, out_root) = main(
        nullifier,
        secret,
        proof_len,
        indices,
        siblings,
        expected_root,
        expected_nullifier_hash,
    );

    println("\nLeaf (commitment):");
    println(out_leaf);
    println("\nMerkle Root:");
    println(out_root);
    println("\nExpected Merkle Root:");
    println(expected_root);
    println("\nExpected Nullifier Hash:");
    println(expected_nullifier_hash);
}

#[test]
fn test_deeper_merkle_tree() {
    // Test with a deeper tree (proof_length = 3)
    let nullifier = 555666777;
    let secret    = 888999000;

    let proof_len = 3;
    let indices   = [1, 0, 1, 0, 0, 0, 0, 0, 0, 0]; // right, left, right path

    let sibling0 = 100;
    let sibling1 = 200;
    let sibling2 = 300;

    let siblings = [
        sibling0, sibling1, sibling2,
        0,0,0,0,0,0,0
    ];

    // Calculamos el root manualmente siguiendo el path
    let leaf = poseidon2([nullifier, secret]);
    
    // Level 0: current is right child (index=1), so hash(sibling0, leaf)
    let level0 = poseidon2([sibling0, leaf]);
    
    // Level 1: current is left child (index=0), so hash(level0, sibling1)
    let level1 = poseidon2([level0, sibling1]);
    
    // Level 2: current is right child (index=1), so hash(sibling2, level1)
    let expected_root = poseidon2([sibling2, level1]);
    
    let expected_nullifier_hash = poseidon1([nullifier]);

    let (out_leaf, out_root) = main(
        nullifier,
        secret,
        proof_len,
        indices,
        siblings,
        expected_root,
        expected_nullifier_hash,
    );

    assert(out_leaf == leaf);
    assert(out_root == expected_root);

    println("\n=== Deeper Tree Test ===");
    println("Leaf (commitment):");
    println(out_leaf);
    println("Computed Root:");
    println(out_root);
    println("Expected Root:");
    println(expected_root);
    println("Path: right -> left -> right");
}
