// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./MyNFT.sol";

contract TokenWrapper {
    mapping(address => bool) public allowedTokens;

    address public owner;

    uint256 public protocolFee = 5;
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public usdcBalance;

    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IUniswapV2Router02 public uniswapRouter;

    event TokensWrapped(address indexed tokenAddress, address indexed sender, uint256 amount, uint256 indexed tokenId);
    event TokensUnwrapped(address indexed tokenAddress, address indexed sender, uint256 amount, uint256 indexed tokenId);
    event TokenAdded(address indexed tokenAddress, address indexed sender);
    event TokenRemoved(address indexed tokenAddress, address indexed sender);
    event ProtocolFeeChanged(uint256 fee);

    constructor(address _uniswapRouter) {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function wrapTokens(address _tokenAddress, uint256 _amount) public {
        require(allowedTokens[_tokenAddress], "Token not allowed");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);

        uint256 tokenId_ = uint256(keccak256(abi.encodePacked(msg.sender, _tokenAddress, _amount, block.timestamp)));

        MyNFT nft = new MyNFT();
        nft.mint(msg.sender);
        nft.transferFrom(address(this), msg.sender, tokenId_);

        emit TokensWrapped(_tokenAddress, msg.sender, _amount, tokenId_);
    }

    // function wrapTokens(address _tokenAddress, uint256 _amount, address _nftAddress) public {
    //     require(allowedTokens[_tokenAddress], "Token not allowed");
    //     require(_amount > 0, "Amount must be greater than zero");

    //     IERC20 token = IERC20(_tokenAddress);
    //     uint256 allowance = token.allowance(msg.sender, address(this));
    //     require(allowance >= _amount, "Caller must approve contract to spend tokens");

    //     require(_nftAddress != address(0), "Invalid NFT address");
    //     MyNFT nft = MyNFT(_nftAddress);

    //     // Generate unique and deterministic NFT token ID
    //     uint256 tokenId_ = uint256(keccak256(abi.encodePacked(msg.sender, _tokenAddress, _amount, block.timestamp)));

    //     // Transfer ERC20 tokens to contract
    //     token.transferFrom(msg.sender, address(this), _amount);

    //     // Mint and transfer NFT token to caller
    //     nft.mint(msg.sender);
    //     nft.transferFrom(address(this), msg.sender, tokenId_);

    //     emit TokensWrapped(_tokenAddress, msg.sender, _amount, tokenId_);
    // }

    function unwrapTokens(address _tokenAddress, uint256 _tokenId) public {
        MyNFT nft = MyNFT(address(this));
        require(nft.ownerOf(_tokenId) == msg.sender, "Sender does not own this NFT");

        uint256 _amount = getWrappedTokenAmount(_tokenId);
        require(_amount > 0, "Invalid NFT");

        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, _amount);

        nft.burn(_tokenId);

        emit TokensUnwrapped(_tokenAddress, msg.sender, _amount, _tokenId);
    }

    function addToken(address _tokenAddress) public onlyOwner {
        require(!allowedTokens[_tokenAddress], "Token already allowed");

        allowedTokens[_tokenAddress] = true;
        emit TokenAdded(_tokenAddress, msg.sender);
    }

    function removeToken(address _tokenAddress) public onlyOwner {
        require(allowedTokens[_tokenAddress], "Token not allowed");

        allowedTokens[_tokenAddress] = false;
        emit TokenRemoved(_tokenAddress, msg.sender);
    }

    function getWrappedTokenAmount(uint256 _tokenId) public view returns (uint256) {
        MyNFT nft = MyNFT(address(this));
        require(nft.ownerOf(_tokenId) != address(0), "Invalid NFT");

        bytes memory data = abi.encode(nft.tokenURI(_tokenId));
        (uint256 amount) = abi.decode(data, (uint256));
        return amount;
    }

    function setProtocolFee(uint256 _protocolFee) public onlyOwner {
        require(_protocolFee < FEE_DENOMINATOR, "Fee can't be higher than 100%");
        protocolFee = _protocolFee;
        emit ProtocolFeeChanged(_protocolFee);
    }

    function withdrawFees() public onlyOwner {
        uint256 feeAmount = usdcBalance * protocolFee / FEE_DENOMINATOR;
        usdc.approve(address(uniswapRouter), feeAmount);

        address[] memory path = new address[](2);
        path[0] = address(usdc);
        path[1] = uniswapRouter.WETH();

        IUniswapV2Router02(uniswapRouter).swapExactTokensForETH(
            feeAmount,
            0,
            path,
            msg.sender,
            block.timestamp
        );

        usdcBalance -= feeAmount;
    }

    function deposit() public payable {
        require(msg.sender == address(usdc), "Invalid sender");
        usdcBalance += msg.value;
    }
}
