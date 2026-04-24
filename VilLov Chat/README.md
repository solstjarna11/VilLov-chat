# VilLov Chat — README.md

## Overview

**VilLov Chat** is the client application for VilLov Private Messaging, implementing all **end-to-end cryptographic operations on-device**.

This is a **client-centric E2EE system**, meaning:

- Encryption and decryption occur only on user devices  
- Private keys never leave the device  
- The server only relays ciphertext  

---

## Core Features

- End-to-End Encrypted Messaging  
- Passkey Authentication (WebAuthn / dev fallback)  
- Forward Secrecy via Double Ratchet  
- Asynchronous Messaging (offline support)  
- Identity Verification (safety numbers)  
- Multi-device support  
- Encrypted local storage  

---

## Cryptographic Architecture

### Identity Keys

Each device generates:

- **Signing Identity Key** → authentication & signatures  
- **Agreement Identity Key** → key exchange  

Stored locally and never shared.

---

### Key Exchange

- X3DH-style asynchronous key agreement  
- Uses:
  - Identity keys  
  - Signed prekeys  
  - One-time prekeys  

---

### Message Encryption

- AES-GCM (AEAD)  
- New key per message  
- Derived via Double Ratchet  

---

### Key Evolution

- Chain keys → message keys  
- Provides:
  - Forward secrecy  
  - Post-compromise recovery  

---

## Identity Verification

Users verify contacts via a **shared safety number**, derived from:

- Local identity keys  
- Remote identity keys  

### Behavior on Key Change

If backend keys are modified:

- Client detects mismatch  
- Trust state changes: `verified → changed`  
- Safety number changes  
- User must re-verify  

Existing sessions may continue, but new sessions will reflect the change.

---

## Local Security

### Secure Storage

- AES-GCM encrypted storage  
- 256-bit Keychain-backed master key   

### Data Stored Locally

- Identity keys  
- Session keys  
- Cached messages  
- Trust state  

---

## Message Flow

1. User authenticates (passkey)  
2. Fetch recipient key bundle  
3. Perform key agreement  
4. Derive session keys  
5. Encrypt message locally  
6. Send ciphertext to server  
7. Recipient decrypts locally  

---

## Security Properties

- **Confidentiality:** Only endpoints can decrypt  
- **Integrity:** Tampering detected via AEAD  
- **Authenticity:** Verified identities and signatures  
- **Forward Secrecy:** Double Ratchet  
- **Post-compromise recovery:** Key evolution  

---

## Residual Risks

- Metadata leakage  
- Device compromise  
- User not verifying identities  

---

## Passkey Authentication

### Supported Modes

#### 1. Real WebAuthn (intended)

- Platform authenticator (Face ID / Touch ID)  
- Private key never leaves device  
- Strong phishing resistance  

#### 2. Dev Passkey Fallback

- Simulated authenticator  
- App-managed key pair  
- Reduced security guarantees  

---

## Security Warning

The development passkey system:

- Is for demonstration only  
- Is NOT secure for production  
- Must be replaced with real WebAuthn  

---

## UI Security Features

- Safety number / identity verification UI  
- Trust state indicators:
  - Verified  
  - Changed  
  - Unverified  
- Warnings on identity changes  

---

## Testing Coverage

Includes tests for:

- Double Ratchet correctness  
- Replay attack prevention  
- Skipped message handling  
- Session persistence  
- Identity trust changes  
- Signed prekey rotation  

---

## Running the Client

### Requirements

- Xcode  
- iOS device or simulator  
- Running VilLov-API backend  

### Setup

1. Open project in Xcode  
2. Configure API endpoint  
3. Run on device  

---

## Summary

VilLov Chat is a **secure client-side cryptographic engine** that:

- Enforces end-to-end encryption  
- Keeps all secrets on-device  
- Detects identity changes and attacks  
- Works with a zero-knowledge backend  

Together with VilLov-API, it forms a modern secure messaging system inspired by real-world designs such as Signal.
