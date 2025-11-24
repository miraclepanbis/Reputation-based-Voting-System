# 🗳️ Reputation-Based Voting System

A decentralized autonomous organization (DAO) governance system built on Stacks blockchain where voting power is determined by member reputation based on historic contributions and participation.

## 🌟 Features

- **🏆 Reputation System**: Members build reputation through contributions and active participation
- **⚖️ Weighted Voting**: Voting power scales with reputation, ensuring experienced contributors have greater influence
- **📊 Proposal Management**: Create, vote on, and execute governance proposals
- **🤝 Reputation Delegation**: Transfer reputation between members for flexible governance
- **🎯 Quorum Requirements**: Proposals must meet minimum participation thresholds
- **⏰ Time-bounded Voting**: Fixed voting periods for fair participation

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
git clone <repository-url>
cd reputation-based-voting-system
clarinet integrate
```

## 📋 Usage

### 1️⃣ Register as a Member

```clarity
(contract-call? .reputation-based-voting-system register-member)
```

New members start with 1 reputation point.

### 2️⃣ Create a Proposal

```clarity
(contract-call? .reputation-based-voting-system create-proposal 
    "Proposal Title" 
    "Detailed description of the proposal")
```

**Requirements**: Minimum 10 reputation points to create proposals.

### 3️⃣ Vote on Proposals

```clarity
;; Vote YES
(contract-call? .reputation-based-voting-system vote u1 true)

;; Vote NO  
(contract-call? .reputation-based-voting-system vote u1 false)
```

Voting automatically increases your reputation by 1 point.

### 4️⃣ Execute Proposals

```clarity
(contract-call? .reputation-based-voting-system execute-proposal u1)
```

Proposals can be executed after the voting period ends if they meet quorum requirements.

### 5️⃣ Delegate Reputation

```clarity
(contract-call? .reputation-based-voting-system delegate-reputation 
    'ST1MEMBER-PRINCIPAL 
    u5)
```

Transfer reputation points to other members for strategic governance.

## 🔍 Read-Only Functions

### Check Member Data
```clarity
(contract-call? .reputation-based-voting-system get-member-data 'ST1MEMBER-PRINCIPAL)
```

### View Proposal Details
```clarity
(contract-call? .reputation-based-voting-system get-proposal u1)
```

### Calculate Voting Power
```clarity
(contract-call? .reputation-based-voting-system calculate-voting-power 'ST1MEMBER-PRINCIPAL)
```

## ⚙️ Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| `MIN-REPUTATION-TO-PROPOSE` | 10 | Minimum reputation required to create proposals |
| `VOTING-PERIOD` | 144 blocks | Duration of voting period (~24 hours) |
| `QUORUM-THRESHOLD` | 50% | Minimum participation required for proposal execution |

## 🏗️ Architecture

### Data Structures

- **Members**: Stores reputation, contributions, and join block for each member
- **Proposals**: Contains proposal details, voting results, and execution status  
- **Votes**: Records individual votes with reputation weights
- **Reputation Actions**: Tracks member activities

### Reputation Calculation

Voting power = Base Reputation + Contribution Bonus + Longevity Bonus

- **Base Reputation**: Earned through voting and successful proposals
- **Contribution Bonus**: Based on total historical contributions  
- **Longevity Bonus**: Increases with membership duration

## 🛡️ Security Features

- ✅ Authorization checks for all sensitive operations
- ✅ Duplicate vote prevention
- ✅ Time-bound proposal voting
- ✅ Quorum enforcement for proposal execution
- ✅ Reputation transfer validation

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

## 📄 License

This project is licensed under the MIT License.



---

Built with ❤️ for decentralized governance on Stacks blockchain.
