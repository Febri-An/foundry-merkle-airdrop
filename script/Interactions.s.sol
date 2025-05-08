//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

contract ClaimAirdrop is Script {
    error __ClaimAirdropScript_InvalidSignatureLength();

    // using anvil default address
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 CLAMING_AMOUNT = 25e18;
    bytes32 PROOF_ONE = 0x72995a443d90c829031cb42be582996fb8747dc02130f358dba0ad65c8db5119;
    bytes32 PROOF_TWO =0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE = hex"fbd2270e6f23fb5fe9248480c0f4be8a4e9bd77c3ad0b1333cc60b5debc511602a2a06c24085d8d7c038bad84edc53664c8ce0346caeaa3570afec0e61144dc11c";

    // function run() external {
    //     address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
    //     verifyAirdrop(mostRecentlyDeployed);
    // }
    
    function verifyAirdrop(address airdropAddress) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdropAddress).verifyEligibility(CLAIMING_ADDRESS, CLAMING_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }

    function claimAirdrop(address airdropAddress) public {
        vm.startBroadcast();
        MerkleAirdrop(airdropAddress).claim(CLAIMING_ADDRESS);
        vm.stopBroadcast();
    }

    function splitSignature(bytes memory signature) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (signature.length != 65) {
            revert __ClaimAirdropScript_InvalidSignatureLength();
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        // v += (v < 27) ? 27 : 0;
    }
}
