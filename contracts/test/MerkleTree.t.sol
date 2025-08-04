// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/TornadoCash.sol";
import { PoseidonT3 } from "poseidon-solidity/PoseidonT3.sol";


contract MerkleTreeTest is Test {
    MerkleTree tree;
    uint256 constant MAX_DEPTH = 10;

    function setUp() public {
        tree = new MerkleTree(10); // árbol de 10 niveles para coincidiir con el circuito
    }
    function testInsertionAndRoot() public {
        uint256 leaf0 = uint256(keccak256("a"));
        uint256 leaf1 = uint256(keccak256("b"));
        uint256 leaf2 = uint256(keccak256("c"));

        uint256 initialRoot = tree.getRoot();

        uint32 index0 = tree.insert(leaf0);
        uint32 index1 = tree.insert(leaf1);
        uint32 index2 = tree.insert(leaf2);

        assertEq(index0, 0);
        assertEq(index1, 1);
        assertEq(index2, 2);

        uint256 finalRoot = tree.getRoot();
        assertTrue(
            finalRoot != initialRoot,
            "Root should change after insertions"
        );
        assertEq(tree.nextIndex(), 3);
    }

    function testNoirRootConsistency() public {
        uint256 entry = uint256(
            uint160(0x742d35Cc6634C0532925a3b844Bc454e4438f44e)
        );

        uint256[10] memory siblings = [
            uint256(
                uint160(bytes20(hex"8626f6940e2eb28930efb4cef49b2d1f2c9c1199"))
            ),
            uint256(
                0x159a0fb15e0498ecdcab51111aa7a8bcc342dc9a75ee428427ead7694fc31fd8
            ),
            uint256(
                0x1069673dcdb12263df301a6ff584a7ec261a44cb9dc68df067a4774460b1f1e1
            ),
            uint256(
                0x18f43331537ee2af2e3d758d50f72106467c6eea50371dd528d57eb2b856d238
            ),
            uint256(
                0x7f9d837cb17b0d36320ffe93ba52345f1b728571a568265caac97559dbc952a
            ),
            uint256(
                0x2b94cf5e8746b3f5c9631f4c5df32907a699c58c94b2ad4d7b5cec1639183f55
            ),
            uint256(
                0x2dee93c5a666459646ea7d22cca9e1bcfed71e6951b953611d11dda32ea09d78
            ),
            uint256(
                0x78295e5a22b84e982cf601eb639597b8b0515a88cb5ac7fa8a4aabe3c87349d
            ),
            uint256(
                0x2fa5e5f18f6027a6501bec864564472a616b2e274a41211a444cbe3a99f3cc61
            ),
            uint256(
                0xe884376d0d8fd21ecb780389e941f66e45e7acce3e228ab3e2156a614fcd747
            )
        ];
        uint8[10] memory indices = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; // izquierda en todos

        uint256 root = entry;
        for (uint256 i = 0; i < 10; i++) {
            if (indices[i] == 0) {
                root = PoseidonT3.hash([root, siblings[i]]);
            } else {
                root = PoseidonT3.hash([siblings[i], root]);
            }
        }

        assertEq(
            root,
            0x2615cf131db524329173504474a6b17ae18856c4d8e4e33e31f5961c1f843be,
            "Merkle root must match Noir"
        );
    }
    function hashPair(
        uint256 left,
        uint256 right
    ) internal pure returns (uint256) {
        return PoseidonT3.hash([left, right]);
    }
}
