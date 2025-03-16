# HyperBoreSplitter

HyperBoreSplitter is a smart contract for automated splitting of funds and fees on EVM-compatible blockchains. It allows for the distribution of ERC-20 tokens among multiple payees based on predefined shares, with the remainder sent to a DAO multisig address.

## Features

- Add, remove, and edit payees with their respective split shares
- Withdraw funds and distribute them among payees
- DAO multisig address management

## Variants

There is another contract in this repo, `Splitter-Treasury`, that divorces payment and contract management. The managing DAO can indicate a treasury address for the purposes of receiving the remainder of value owned by the contract, otherwise, contracts are identical.

## Caveats

- Currently, there are no tests on the splitter contract.
- Currently, funds are not recoverable if payee list is empty and daoMultisig is lost.
- Edits must be made to Hardhat Ignition for deployment.

## Events

Index these events for data analytics and dashboarding.

- `FundsWithdrawn(address recipient, uint256 amount)`: Emitted when funds are withdrawn and distributed.
- `DAOAddressChanged(address indexed daoMultisig)`: Emitted when the DAO multisig address is changed.

## Contract Details

### Constructor

```solidity
constructor(address _daoMultisig)
```

- `_daoMultisig`: The address of the DAO multisig. Must not be the zero address.

### Functions

`updateDAOMultisig`

```solidity
function updateDAOMultisig(address _newMultisig) external onlyDAO
```

- Updates the DAO multisig address (in case of moving multisig providers)
- Only callable by the current DAO multisig
- `_newMultisig`: The new DAO multisig address. Must not be the zero address.

`addPayee`

```solidity
function addPayee(address _newPayee, uint8 _newShare) external onlyDAO
```

- Adds a new payee with a specified share.
- Only callable by the DAO multisig.
- `_newPayee`: The address of the new payee.
- `_newShare`: The share of the new payee. Total shares across all payees must not exceed 50%.

`removePayee`

```solidity
function removePayee(address _payee) external onlyDAO
```

- Removes an existing payee.
- Only callable by the DAO multisig.
- `_payee`: The address of the payee to be removed.

`editPayees`

```solidity
function editPayees(Payee[] calldata _payees) external onlyDAO
```

- Edits the list of payees and their respective shares.
- Only callable by the DAO multisig.
- `_payees`: An array of Payee structs containing the new payees and their shares. Total shares across all payees must not exceed 50%.

`withdraw`

```solidity
function withdraw(uint256 _amount, address _token) external onlyPayee nonReentrant
```

- Withdraws a specified amount of ERC-20 tokens and distributes them among the payees.
- Only callable by a listed Payee.
- `_amount`: The total amount to be withdrawn and distributed. Will fail if more than the contract has been assigned.
- `_token`: The address of the ERC-20 token to be withdrawn.

## License

This project is licensed under the MIT License. Please remix it for your own needs and make beautiful, co-operative things.

## Sponsorship

This project is sponsored by [HyperBoreDAO](https://www.hyperboredao.ai/)
