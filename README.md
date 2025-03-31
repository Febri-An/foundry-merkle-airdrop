# MerkleAirdrop: Secure Airdrop with Signatures & Merkle Proof 🚀🔐

## Overview 🎯
**MerkleAirdrop** is a smart contract designed for efficient and secure token distribution using **Merkle proofs** and **EIP-712 signatures**. This contract ensures that only eligible users can claim their tokens while also supporting a third-party fee payer mechanism, allowing a user to cover the transaction fee for another recipient. 🔗💰

## Features 🌟
- **Merkle Proof Verification**: Ensures only valid recipients can claim tokens.
- **EIP-712 Signature Authentication**: Adds an extra layer of security by verifying off-chain signatures.
- **Fee Payer Support**: Users can sponsor claim transactions for others.
- **Prevent Double Claims**: Each recipient can claim their airdrop only once.
- **ERC-20 Safe Transfers**: Uses OpenZeppelin’s SafeERC20 to prevent token transfer failures. 🏦🔒

---
## How It Works 📜
1. **Merkle Root Setup**: The contract is initialized with a **Merkle Root** representing all eligible airdrop recipients.
2. **User Claim Process**:
   - The user submits a claim with their **Merkle proof** and **signed message**.
   - The contract verifies the **Merkle proof** and **signature**.
   - If valid, the tokens are transferred to the recipient.
3. **Fee Payer Mechanism**:
   - A different address can pay gas fees for the recipient’s claim, making it gasless for them. ⚙️💳

---
## Contract Details 📑🔍
### State Variables 🏗️
| Variable | Type | Description |
|----------|------|-------------|
| `i_merkleRoot` | `bytes32` | Root of the Merkle tree containing eligible addresses. |
| `i_airdropToken` | `IERC20` | The ERC-20 token being airdropped. |
| `s_hasClaimed` | `mapping(address => bool)` | Tracks whether an address has already claimed. |
| `MESSAGE_TYPEHASH` | `bytes32` | Typehash for EIP-712 structured message signing. |

### Events 📢
| Event | Parameters | Description |
|--------|------------|-------------|
| `Claim` | `address account, uint256 amount` | Emitted when an account successfully claims tokens. |

### Functions 🔧
#### `claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)`
Allows a user to claim their airdrop after verifying:
- They haven’t already claimed.
- Their **Merkle proof** is valid.
- Their **EIP-712 signature** is valid. ✅🔐📜

#### `getMessageHash(address account, uint256 amount) → bytes32`
Returns the **hashed message** used for signature verification. 🔄🔎📨

#### `getMerkleRoot() → bytes32`
Returns the stored **Merkle Root**. 🌳🔗📜

#### `getAirDropToken() → IERC20`
Returns the **airdrop token** address. 💰🪙🔍

#### `_isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s) → bool`
Checks if the **EIP-712 signature** is valid. 🔏✅📜

---
## Security Considerations 🚨
- **Merkle Root Integrity**: Ensure the root is generated correctly and securely shared.
- **Off-Chain Signature Verification**: Always verify the signed message before submitting.
- **Gasless Claiming Risks**: Fee payers should trust recipients before covering fees. ⚠️🔎

---
## Example Usage 🖥️
```solidity
// Assume you have Merkle proof, signature, and claim details
merkleAirdrop.claim(
    recipientAddress,
    claimAmount,
    merkleProof,
    v, r, s
);
```

## License 📜
This project is licensed under the **MIT License**. 🎓⚖️

