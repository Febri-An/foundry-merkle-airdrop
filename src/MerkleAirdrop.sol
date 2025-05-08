// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712{
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyVerified();
    error MerkleAirdrop__InvalidSignature();
    error MerkleAirdrop__NotVerified();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidClaimInterval();

    struct ClaimInfo {
        uint256 totalAmount;       // Total eligible amount
        uint256 claimedAmount;     // Already claimed amount
        uint256 lastClaimTime;     // Timestamp of the last claim
    }
    
    // address[] claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address => ClaimInfo) public s_claimInfo;
    mapping(address => bool) private s_isVerified;

    bytes32 public constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");
    uint256 public constant TIME_INTERVAL = 30 days;
    uint256 public constant INITIAL_CLAIM_PERCENTAGE = 4; // 25% of the total amount
    uint256 public constant VESTING_RATE = 75; // 75% of the remaining amount
    uint256 public constant PERCENTAGE_DENOMINATOR = 100;

    struct AirdropClaim {
        address account;
        uint256 amount;   
    }

    event Verified(address account, uint256 amount);
    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    /**
     * Verifies a user's eligibility for the airdrop.
     * @param account The address of the user.
     * @param amount The amount of tokens the user is eligible to claim.
     * @param merkleProof The Merkle proof validating the user's eligibility.
     * @dev Reverts if the user is already verified, the signature is invalid, or the Merkle proof is invalid.
     * @notice Other users can verify the eligibility of other users.
     */
    function verifyEligibility(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s) external {
        if (s_isVerified[account]) {
            revert MerkleAirdrop__AlreadyVerified();
        }
        // check the permission
        if (!_isValidSignature(account, getMessageHash(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        // verify the proof
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        uint256 amountToClaim = amount / INITIAL_CLAIM_PERCENTAGE;
        
        s_isVerified[account] = true;
        s_claimInfo[account] = ClaimInfo({
            totalAmount: amount,
            claimedAmount: amountToClaim,
            lastClaimTime: block.timestamp
        });
        emit Verified(account, amount);
        i_airdropToken.safeTransfer(account, amountToClaim);
    }

    /**
     * Claims the airdrop tokens for the user.
     * @param account The address of who verified the eligibility.
     * @dev Reverts if the user is not verified or has already claimed the tokens.
     */
    function claim(address account) public {
        if (!s_isVerified[account]) {
            revert MerkleAirdrop__NotVerified();
        }
        // Check if the claim interval has passed
        if (block.timestamp - s_claimInfo[account].lastClaimTime < TIME_INTERVAL) {
            revert MerkleAirdrop__InvalidClaimInterval();
        }
        // Check remaining tokens
        if (s_claimInfo[account].claimedAmount >= s_claimInfo[account].totalAmount) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // 25% of the remaining amount can be claimed every 30 days
        uint256 amountToClaim = (((s_claimInfo[account].totalAmount * VESTING_RATE) / PERCENTAGE_DENOMINATOR) / INITIAL_CLAIM_PERCENTAGE);
        s_claimInfo[account].claimedAmount += amountToClaim;
        s_claimInfo[account].lastClaimTime = block.timestamp;
        
        emit Claim(account, amountToClaim);
        i_airdropToken.safeTransfer(account, amountToClaim);
    }

    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount})))
        );
    }

    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (bool) {
        // Check if the signature is valid
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return (actualSigner == account);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}