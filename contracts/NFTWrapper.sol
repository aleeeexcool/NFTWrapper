//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTWrapper is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter public allIds;

    address public owner;
    address public usdcAddress;
    address public routerAddress;

    uint public protocolFee = 5;
    uint public constant FEE_DENOMINATOR = 1000;
    uint public feeAmount;

    struct WrappedTokens {
        address minter;
        uint amount;
        address tokenAddress;
    }

    mapping(address => bool) public allowedTokens;
    mapping(uint => WrappedTokens) public tokenIds;

    event TokensWrapped(address indexed tokenAddress, address indexed sender, uint amount, uint indexed tokenId);
    event TokensUnwrapped(address indexed tokenAddress, address indexed sender, uint amount, uint indexed tokenId);
    event TokenAdded(address indexed tokenAddress, address indexed sender);
    event TokenRemoved(address indexed tokenAddress, address indexed sender);
    event ProtocolFeeChanged(uint fee);

    constructor(address _usdcAddress, address _routerAddress) ERC721("MyNFT", "MNFT") {
        owner = msg.sender;
        usdcAddress = _usdcAddress; //0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
        routerAddress = _routerAddress; //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function wrapTokens(address _tokenAddress, uint _amount) public {
        require(allowedTokens[_tokenAddress] == true, "Token not allowed");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(_tokenAddress);
        // @dev: before transferFrom, user must approve this contract to spend their tokens
        // There are two ways to do this:
        // 1. Call approve() using front-end to get approval from user
        // 2. The user must approve it themselves using the ERC20 approve() function
        token.transferFrom(tx.origin, address(this), _amount);

        uint newId = allIds.current();
        allIds.increment();
        _safeMint(msg.sender, newId);

        tokenIds[newId] = WrappedTokens(msg.sender, _amount, _tokenAddress);

        emit TokensWrapped(_tokenAddress, msg.sender, _amount, newId);
    }

    function unwrapTokens(address _tokenAddress, uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Sender does not own this NFT");
        require(allowedTokens[_tokenAddress] == true, "Token not allowed");
        require(tokenIds[_tokenId].tokenAddress == _tokenAddress, "Invalid token address");

        uint amount_ = getWrappedTokenAmount(_tokenId);
        _burn(_tokenId);
        delete tokenIds[_tokenId];
        uint fee = amount_ * protocolFee / FEE_DENOMINATOR;
        uint amountWithoutFee = amount_ - fee;
        feeAmount += fee;

        IERC20 token = IERC20(_tokenAddress);
        token.transfer(tx.origin, amountWithoutFee);

        emit TokensUnwrapped(_tokenAddress, msg.sender, amountWithoutFee, _tokenId);
    }

    function getWrappedTokenAmount(uint _tokenId) public view returns (uint) {
        require(ownerOf(_tokenId) != address(0), "Invalid NFT");

        uint amount = tokenIds[_tokenId].amount;
        return amount;
    }

    function addToken(address _tokenAddress) public onlyOwner {
        require(allowedTokens[_tokenAddress] != true, "Token already allowed");

        allowedTokens[_tokenAddress] = true;
        emit TokenAdded(_tokenAddress, msg.sender);
    }

    function removeToken(address _tokenAddress) public onlyOwner {
        require(allowedTokens[_tokenAddress] != false, "Token not allowed");

        allowedTokens[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress, msg.sender);
    }

    function setProtocolFee(uint _protocolFee) public onlyOwner {
        require(_protocolFee <= FEE_DENOMINATOR, "Fee can't be higher than 100%");
        protocolFee = _protocolFee;

        emit ProtocolFeeChanged(_protocolFee);
    }

    function withdrawFees(address _tokenAddress) public onlyOwner {
        require(allowedTokens[_tokenAddress] != false, "Token not allowed");

        IERC20 token = IERC20(_tokenAddress);
        uint erc20Balance = token.balanceOf(owner);
        require(erc20Balance >= feeAmount, "Insufficient ERC20 balance");

        IERC20 usdc = IERC20(usdcAddress);

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        token.approve(routerAddress, feeAmount);
        address[] memory path = new address[](2);
        path[0] = _tokenAddress;
        path[1] = usdcAddress;
        uint[] memory amounts = router.swapExactTokensForTokens(
            feeAmount, 
            0, 
            path, 
            address(this), 
            block.timestamp + 1000);
        
        feeAmount = 0;
        uint usdcAmount = amounts[1];
        usdc.transfer(owner, usdcAmount);
    }
}
