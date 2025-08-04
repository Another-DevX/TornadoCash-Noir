// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "poseidon-solidity/PoseidonT3.sol";
import "./Verifier.sol";

contract MerkleTree {
    uint256 public root;

    uint256 public constant ZERO_VALUE = uint256(keccak256("tornado-keccak"));

    uint32 public immutable levels;
    uint32 public nextIndex = 0;

    uint256[] public filledSubtrees;
    uint256[] public zeros;

    constructor(uint32 _levels) {
        require(_levels > 0 && _levels < 32, "Invalid tree height");
        levels = _levels;

        uint256 currentZero = ZERO_VALUE;
        zeros.push(currentZero);
        filledSubtrees.push(currentZero);

        for (uint32 i = 1; i < _levels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        root = hashLeftRight(currentZero, currentZero);
    }

    function insert(uint256 leaf) public returns (uint32 insertedIndex) {
        require(nextIndex < uint32(2) ** levels, "Merkle tree is full");

        uint32 currentIndex = nextIndex;
        nextIndex += 1;

        uint256 currentHash = leaf;
        uint256 left;
        uint256 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentHash;
                right = zeros[i];
                filledSubtrees[i] = currentHash;
            } else {
                left = filledSubtrees[i];
                right = currentHash;
            }

            currentHash = hashLeftRight(left, right);
            currentIndex /= 2;
        }

        root = currentHash;
        return nextIndex - 1;
    }

    function getRoot() external view returns (uint256) {
        return root;
    }

    function hashLeftRight(
        uint256 left,
        uint256 right
    ) internal pure returns (uint256 result) {
        return PoseidonT3.hash([left, right]);
    }
}

contract TornadoCashLite is MerkleTree {
    HonkVerifier public verifier;

    mapping(bytes32 => bool) public commitments;
    mapping(bytes32 => bool) public nullifiers;

    event Deposit(
        bytes32 indexed commitment,
        uint32 leafIndex,
        uint256 timestamp
    );

    event Withdrawal(
        address indexed recipient,
        bytes32 indexed nullifier,
        uint256 timestamp
    );

    constructor(uint32 _levels) MerkleTree(_levels) {
        verifier = new HonkVerifier();
    }

    function deposit(bytes32 _commitment) external payable {
        require(!commitments[_commitment], "Commitment already submitted");
        require(msg.value == 0.1 ether, "Must send 0.1 ETH to deposit");

        uint32 insertedIndex = insert(uint256(_commitment));
        commitments[_commitment] = true;

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    function withdraw(
        bytes32 _nullifier,
        address payable _recipient,
        bytes32 proof
    ) external {
        require(!nullifiers[_nullifier], "Note already spent");

        nullifiers[_nullifier] = true;

        // Verify the nullifier using the Verifier contract
        bytes32[2] memory inputs = [bytes32(root), _nullifier];
        require(
            verifier.verify(proof, inputs),
            "Invalid nullifier proof"
        );

        // For now just emit, you can add ETH transfer logic later
        emit Withdrawal(_recipient, _nullifier, block.timestamp);
    }
}
