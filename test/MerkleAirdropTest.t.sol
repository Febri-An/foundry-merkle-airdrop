// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {BagelToken} from "src/BagelToken.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    BagelToken token;
    MerkleAirdrop airdrop;

    bytes32 public ROOT = 0x7cdb6c21ef22a6cb5726d348e677f3e10032127425d425c5028965a30a71556e;
    uint256 public AMOUNT_TO_CLAIM = 25e18;
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [
        proofOne,
        proofTwo
    ];
    address USER;
    uint256 privateKey;
    address GAS_PAYER;

    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (token, airdrop) = deployer.run();
        } else {
            token = new BagelToken();
            airdrop = new MerkleAirdrop(ROOT, token);
            token.mint(address(airdrop), AMOUNT_TO_SEND);
        }
        (USER, privateKey) = makeAddrAndKey("USER");
        GAS_PAYER = makeAddr("GAS_PAYER");
    }

    function testUserCanClaim() public {
        uint256 startingBalance = token.balanceOf(USER);
        bytes32 digest = airdrop.getMessageHash(USER, AMOUNT_TO_CLAIM);

        // sign a message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        // gasPayer pays for the transaction
        vm.prank(GAS_PAYER);
        airdrop.claim(USER, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = token.balanceOf(USER);
        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}