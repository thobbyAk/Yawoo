//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./compound/CToken.sol";
import "./compound/Comptroller.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Factory is CToken {
    using SafeMath for uint256;
    address factoryAddress;

    constructor() {}

    struct userBalance {
        address users;
        uint256 supplyBalance;
        uint256 borrowBalance;
        uint256 borrowLimit;
    }

    //map each user to a userbalance
    mapping(address => userBalance) private userId;

    //events
    event assetsMintedToCompund(
        address user,
        uint256 indexed amount,
        uint256 supplyBalance
    );
    event assetsborrowedFromCompund(
        address user,
        uint256 indexed amount,
        uint256 borrowBalance
    );

    /**
     @notice provide collateral to Compound in place of the user
     @param _amount amount of collateral users wants to suply
     @param _user address of the users  that wants to supply an assets
     */
    function mintAssetsToCompound(address _user, uint256 _amount) external {
        require(_amount > 0, "amount must be grater than 0");
        require(_user != address(0), "address must not be a 0 address");

        //check if  user has an initial borrow balalnce
        if (
            userId[_user].borrowBalance == 0 && userId[_user].supplyBalance == 0
        ) {
            uint256 limitValue = 80;
            uint256 percentageValue = limitValue.div(100);
            uint256 borrowLimit = _amount.mul(percentageValue);
            userId[_user] = userBalance(_user, _amount, 0, borrowLimit);
        } else {
            userId[_user].supplyBalance.add(_amount);
        }

        //mint assents on users behalf by factory contract
        mintInternal(_amount);
        emit assetsMintedToCompund(_user, _amount, userId[_user].supplyBalance);
    }

    function fundContract() public payable {
        payable(address(this)).transfer(msg.value);
    }

    /**
     @notice borrow  asset from compound on behalf of the use purchase an item
     @param _amount amount of collateral users wants to suply
     @param _user address of the users  that wants to supply an assets
     */
    function borrowAssetFromCompound(address _user, uint256 _amount) external {
        require(_amount > 0, "amount must be grater than 0");
        require(_user != address(0), "address must not be a 0 address");

        uint256 currentUserSupplyBalance = userId[_user].supplyBalance;
        uint256 limitValue = 80;
        uint256 percentageValue = limitValue.div(100);
        uint256 borrowLimit = currentUserSupplyBalance.mul(percentageValue);
        // update user borrow balance
        require(borrowLimit > _amount, "user unable to borrow");
        userId[_user].borrowBalance.add(_amount);
        borrowLimit = borrowLimit.sub(_amount);
        userId[_user].borrowLimit = borrowLimit;

        borrowInternal(_amount);
        //todo: look for a way to check if the contract has receieved the amount from the contract
        payable(_user).transfer(_amount);
        emit assetsborrowedFromCompund(
            _user,
            _amount,
            userId[_user].borrowBalance
        );
    }

    /**
     @notice repay borrowed assets to compund
     @param _repayAmount amount of collateral users wants to suply
     @param _user address of the users  that wants to supply an assets
     */

    function repayBorrowedAsset(address _user, uint256 _repayAmount) external {
        require(_repayAmount > 0, "amount must be grater than 0");
        require(_user != address(0), "address must not be a 0 address");

        uint256 borrowLimit = userId[_user].borrowLimit;
        require(
            borrowLimit >= _repayAmount,
            "user unable to repay beyond borrow limit"
        );
        userId[_user].borrowBalance = userId[_user].borrowBalance.sub(
            _repayAmount
        );
        userId[_user].borrowLimit = userId[_user].borrowLimit.add(_repayAmount);
        redeemInternal(_repayAmount);
    }

    /*** Safe Token ***/

    /**
     * @notice Gets balance of this contract in terms of Ether, before this message
     * @dev This excludes the value of the current message, if any
     * @return The quantity of Ether owned by this contract
     */
    function getCashPrior() internal view virtual override returns (uint256) {
        return address(this).balance - msg.value;
    }

    /**
     * @notice Perform the actual transfer in, which is a no-op
     * @param from Address sending the Ether
     * @param amount Amount of Ether being sent
     * @return The actual amount of Ether transferred
     */
    function doTransferIn(address from, uint256 amount)
        internal
        virtual
        override
        returns (uint256)
    {
        // Sanity checks
        require(msg.sender == from, "sender mismatch");
        require(msg.value == amount, "value mismatch");
        return amount;
    }

    function doTransferOut(address payable to, uint256 amount)
        internal
        virtual
        override
    {
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
    }

    fallback() external payable {
        // receive money
        fundContract();
    }
}
