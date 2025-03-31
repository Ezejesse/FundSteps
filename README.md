# FundSteps: Milestone-Based Crowdfunding On The Blockchain

A secure and transparent smart contract implementation for milestone-based crowdfunding campaigns on the Stacks blockchain.

## Overview

This smart contract enables project creators to raise funds through a milestone-based approach, where capital is released incrementally as specific project milestones are completed and approved. This model provides enhanced security for contributors by ensuring funds are only released when measurable progress is demonstrated.

## Features

- **Milestone-Based Funding**: Campaigns are structured with three predefined milestones, each requiring approval before funds can be released.
- **Transparent Fund Management**: All contributions and milestone claims are recorded on the blockchain with verifiable transactions.
- **Governance Oversight**: Milestone approvals require verification from the contract administrator, adding an extra layer of protection.
- **Automatic Campaign Closure**: Campaigns automatically close after a predefined duration or after all milestones are completed.

## Technical Specifications

### Data Structures

The contract uses three primary data maps:

1. **Campaigns**: Stores campaign details including owner, funding goals, end date, and status.
2. **Milestones**: Defines the milestone structure for each campaign, including funding amounts and completion status.
3. **Contributions**: Tracks all contributions made to campaigns.

### Key Functions

#### For Campaign Creators

```clarity
(define-public (create-campaign (total-goal uint) (duration uint) (milestone-amounts (list 3 uint)) (milestone-descs (list 3 (string-ascii 100))))
```
Creates a new campaign with specified funding goal, duration, and three milestones.

```clarity
(define-public (claim-milestone (campaign-id uint) (milestone-id uint)))
```
Allows campaign owners to claim funds for approved milestones.

#### For Contributors

```clarity
(define-public (contribute (campaign-id uint) (amount uint)))
```
Enables users to contribute funds to a specific campaign.

#### For Contract Administration

```clarity
(define-public (approve-milestone (campaign-id uint) (milestone-id uint)))
```
Permits the contract owner to approve milestone completion after verification.

#### Read-Only Functions

```clarity
(define-read-only (get-campaign (campaign-id uint)))
(define-read-only (get-milestone (campaign-id uint) (milestone-id uint)))
(define-read-only (get-contribution (campaign-id uint) (contributor principal)))
```
Provide transparency by allowing anyone to view campaign details, milestone status, and contribution records.

## Error Codes

| Code | Description |
|------|-------------|
| `ERR-NOT-AUTHORIZED (u200)` | Operation requires authorization |
| `ERR-CAMPAIGN-NOT-FOUND (u201)` | Referenced campaign does not exist |
| `ERR-MILESTONE-NOT-APPROVED (u202)` | Milestone has not been approved for claim |
| `ERR-CAMPAIGN-ENDED (u203)` | Campaign has ended or is no longer active |
| `ERR-INVALID-MILESTONE (u204)` | Invalid milestone parameters or reference |

## Usage Guide

### Creating a Campaign

1. Determine your total funding goal
2. Define three milestone amounts (must sum to total goal)
3. Provide descriptions for each milestone (max 100 ASCII characters each)
4. Set campaign duration (in blocks)
5. Call the `create-campaign` function

### Contributing to a Campaign

1. Identify the campaign ID you wish to support
2. Determine contribution amount
3. Call the `contribute` function with these parameters

### Claiming Milestone Funds (Campaign Owners)

1. Complete the work associated with a milestone
2. Request milestone approval from contract administrator
3. Once approved, call `claim-milestone` function with campaign and milestone IDs

## Security Considerations

- Funds are locked in the contract until milestones are approved
- Contract owner has oversight of milestone approvals to prevent fraud
- Campaign timeframes are enforced at the blockchain level
- All actions emit events for auditability

## Development and Testing

This contract can be tested using the Clarinet testing framework for Clarity smart contracts. For local development:

1. Install [Clarinet](https://github.com/hirosystems/clarinet)
2. Clone this repository
3. Run `clarinet console` in the project directory
4. Test functions using the Clarinet console

## Deployment

To deploy this contract to the Stacks blockchain:

1. Build the contract using Clarinet
2. Deploy using the Stacks Explorer or CLI tools
3. Verify contract deployment and functionality

## License

MIT
