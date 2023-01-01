// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./utils/BMath.sol";

contract DecentralizedETF is ERC20, BMath {
    bytes32 private constant WBTC = keccak256("WBTC");
    bytes32 private constant WETH = keccak256("WETH");
    address private _owner;
    IERC20 private _wBTC;
    IERC20 private _wETH;
    uint8 private constant WBTC_DECIMALS = 8;
    uint8 private constant WETH_DECIMALS = 18;
    mapping(bytes32 => uint256) public weights;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(
        IERC20 wBTCaddr,
        IERC20 wETHaddr
    ) ERC20("DecentralizedETF ", "DETF") {
        _owner = msg.sender;
        _wBTC = wBTCaddr;
        _wETH = wETHaddr;
        // init mint
        _mint(msg.sender, 10 ** decimals());
    }

    function tokenAmountPerShare()
        public
        view
        returns (uint256 sharePerBTC, uint256 sharePerETH)
    {
        sharePerBTC =
            (_wBTC.balanceOf(address(this)) * 10 ** decimals()) /
            totalSupply();
        sharePerETH =
            (_wETH.balanceOf(address(this)) * 10 ** decimals()) /
            totalSupply();
    }

    // every share include 10000 sats, which is 0.001 wBTC
    function allAssestsDeposit(uint256 share) external {
        (uint256 sharePerBTC, uint256 sharePerETH) = tokenAmountPerShare();
        uint256 amountBTC = sharePerBTC * share;
        uint256 amountETH = sharePerETH * share;
        _wBTC.transferFrom(msg.sender, address(this), amountBTC);
        _wETH.transferFrom(msg.sender, address(this), amountETH);
        _mint(msg.sender, share);
    }

    function allAssestsRedeem(uint256 share) external {
        _burn(msg.sender, share);
        (uint256 sharePerBTC, uint256 sharePerETH) = tokenAmountPerShare();
        uint256 amountBTC = sharePerBTC * share;
        uint256 amountETH = sharePerETH * share;
        _wBTC.transfer(msg.sender, amountBTC);
        _wETH.transfer(msg.sender, amountETH);
    }

    function setWeights(uint256 weightBTC, uint256 weightETH) external {
        weights[WBTC] = weightBTC;
        weights[WETH] = weightETH;
    }

    function swapBTC2ETH(uint256 amount) external {
        uint256 amountETH = calcOutGivenIn(
            _wBTC.balanceOf(address(this)),
            weights[WBTC],
            _wETH.balanceOf(address(this)),
            weights[WETH],
            amount,
            0
        );
        _wBTC.transferFrom(msg.sender, address(this), amount);
        _wETH.transfer(msg.sender, amountETH);
    }

    function swapETH2BTC(uint256 amount) external {
        uint256 amountBTC = calcOutGivenIn(
            _wETH.balanceOf(address(this)),
            weights[WETH],
            _wBTC.balanceOf(address(this)),
            weights[WBTC],
            amount,
            0
        );
        _wETH.transferFrom(msg.sender, address(this), amount);
        _wBTC.transfer(msg.sender, amountBTC);
    }
}
