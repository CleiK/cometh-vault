// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;

import "@Uniswap/contracts/UniswapV2ERC20.sol";
import "@Uniswap/contracts/interfaces/IUniswapV2Pair.sol";
import "./farms/ComethFarm.sol";

contract ComethVault {
    address public farm;
    address public lpToken;
    address public user;

    constructor(
        address _farm,
        address _lpToken,
        address _user
    ) public {
        farm = _farm;
        lpToken = _lpToken;
        user = _user;
    }

    modifier onlyUser() {
        require(
            msg.sender == user,
            "Only the configured user can use this function"
        );
        _;
    }

    function getDeposit() public view onlyUser returns (uint256) {
        StakingMultiRewards comethFarm = StakingMultiRewards(farm);

        // get balance
        return comethFarm.balanceOf(address(this));
    }

    function getAllowance() public view onlyUser returns (uint256) {
        IERC20 lpErc20 = IERC20(lpToken);
        return lpErc20.allowance(msg.sender, address(this));
    }

    function deposit(uint256 _amount) public onlyUser {
        IERC20 lpErc20 = IERC20(lpToken);

        // verify token allowance
        uint256 amountAllowed = lpErc20.allowance(msg.sender, address(this));

        // revert on bad allowance
        require(
            amountAllowed >= _amount,
            "You need to approve token spending or increase allowance"
        );

        // transferFrom sender to this
        lpErc20.transferFrom(msg.sender, address(this), _amount);

        StakingMultiRewards comethFarm = StakingMultiRewards(farm);
        // allow farm
        lpErc20.approve(address(comethFarm), _amount); // ok
        // stake in farm
        comethFarm.stake(_amount); // ne fait rien ?
    }

    function withdraw(uint256 _amount) public onlyUser {
        StakingMultiRewards comethFarm = StakingMultiRewards(farm);

        // get balance
        uint256 balance = comethFarm.balanceOf(address(this));
        require(_amount <= balance, "Cannot withdraw more than deposited");

        // withdraw from farm
        comethFarm.withdraw(_amount);

        // transferFrom this to sender
        IERC20 lpErc20 = IERC20(lpToken);
        lpErc20.approve(msg.sender, _amount);

        // verify token allowance
        uint256 amountAllowed = lpErc20.allowance(address(this), msg.sender);

        // revert on bad allowance
        require(
            amountAllowed >= _amount,
            "allowed is less than desired _amount"
        );

        lpErc20.transferFrom(address(this), msg.sender, _amount);
    }

    function exit() public onlyUser {
        StakingMultiRewards comethFarm = StakingMultiRewards(farm);
        comethFarm.exit();

        IERC20 lpErc20 = IERC20(lpToken);

        uint256 lpBalance = lpErc20.balanceOf(address(this));
        IERC20[] memory rewardsTokens = comethFarm.getRewardsTokens();
        uint256[] memory rewardsBalance = comethFarm.getRewards(address(this));

        // transfer the removed lp tokens
        lpErc20.transferFrom(address(this), msg.sender, lpBalance);
        // transfer the rewards
        for (uint256 i = 0; i < rewardsTokens.length; i++) {
            rewardsTokens[i].transferFrom(
                address(this),
                msg.sender,
                rewardsBalance[i]
            );
        }
    }

    function compound() public {
        StakingMultiRewards comethFarm = StakingMultiRewards(farm);

        // current earned
        uint256[] memory earned = comethFarm.earned(user);
        IERC20[] memory rewardsTokens = comethFarm.getRewardsTokens();

        IUniswapV2Pair uniLp = IUniswapV2Pair(lpToken);

        // sell some..

        // new lp

        // stake lp

        // send remaining tokens
    }
}
