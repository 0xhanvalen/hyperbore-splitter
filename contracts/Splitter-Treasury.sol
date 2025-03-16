// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
using SafeERC20 for IERC20;

/**
 * @title HyperBoreSplitter
 * @author HanValen
 * @notice This contract is for automated splitting of funds and fees on evm-flavoured chains.
 */
contract HyperBoreSplitter is ReentrancyGuard {
    address public daoMultisig;
    address public treasury;
    struct Payee {
        address payeeAddress;
        uint8 splitShare;
    }
    mapping(uint8 => Payee) public Payees;

    event FundsWithdrawn(address recipient, uint256 amount);
    event DAOAddressChanged(address indexed daoMultisig);
    event TreasuryAddressChanged(address indexed treasury);

    constructor(address _daoMultisig, address _treasury) {
        require(_daoMultisig != address(0), "Invalid multisig address");
        require(_treasury != address(0), "Invalid treasury address");
        daoMultisig = _daoMultisig;
        treasury = _treasury;
    }

    modifier onlyDAO() {
        require(msg.sender == daoMultisig, "Uninvolved user");
        _;
    }

    modifier onlyPayee() {
        bool isPayee = false;
        for (uint8 i = 0; i < 255; i++) {
            if (Payees[i].payeeAddress == msg.sender) {
                isPayee = true;
            } else {
                break;
            }
        }
        require(isPayee, "Uninvovled User");
        _;
    }

    function updateDAOMultisig(address _newMultisig) external onlyDAO {
        require(_newMultisig != address(0), "Can't burn contract");
        daoMultisig = _newMultisig;
        emit DAOAddressChanged(_newMultisig);
    }

    function updateTreasury(address _newTreasury) external onlyDAO {
        require(_newTreasury != address(0), "Can't burn funds");
        treasury = _newTreasury;
        emit TreasuryAddressChanged(_newTreasury);
    }

    function addPayee(address _newPayee, uint8 _newShare) external onlyDAO {
        uint8 totalShares = 0;
        uint8 payeeCount = 0;
        for (uint8 i = 0; i < 255; i++) {
            if (Payees[i].payeeAddress != address(0)) {
            totalShares += Payees[i].splitShare;
            payeeCount++;
            } else {
            break;
            }
        }
        require(totalShares + _newShare <= 50, "Total shares exceed 50%");
        
        Payees[uint8(payeeCount + 1)] = Payee(_newPayee, _newShare);
    }

    function removePayee(address _payee) external onlyDAO {
        for (uint8 i = 0; i < 255; i++) {
            if (Payees[i].payeeAddress == _payee) {
                delete Payees[i];
                break;
            }
        }
    }

    function editPayees(Payee[] calldata _payees) external onlyDAO {
        uint8 totalShares = 0;
        for (uint8 i = 0; i < _payees.length; i++) {
            totalShares += _payees[i].splitShare;
        }
        require(totalShares <= 50, "Total shares exceed 50%");

        // Clear existing payees
        for (uint8 i = 0; i < 255; i++) {
            if (Payees[i].payeeAddress != address(0)) {
                delete Payees[i];
            } else {
                break;
            }
        }

        // Add new payees
        for (uint8 i = 0; i < _payees.length; i++) {
            Payees[i] = _payees[i];
        }
    }

    function withdraw(uint256 _amount, address _token) external onlyPayee nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(_token != address(0), "Invalid token address");

        uint256 totalDistributed = 0;
        for (uint8 i = 0; i < 255; i++) {
            if (Payees[i].payeeAddress != address(0)) {
                uint256 shareAmount = (_amount * Payees[i].splitShare) / 100;
                totalDistributed += shareAmount;
                IERC20(_token).safeTransfer(Payees[i].payeeAddress, shareAmount);
                emit FundsWithdrawn(Payees[i].payeeAddress, shareAmount);
            } else {
                break;
            }
        }

        uint256 remainder = _amount - totalDistributed;
        IERC20(_token).safeTransfer(treasury, remainder);
        emit FundsWithdrawn(daoMultisig, remainder);
    }
}