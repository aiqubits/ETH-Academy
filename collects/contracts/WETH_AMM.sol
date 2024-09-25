// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./WETH.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

contract WETH_AMM is ERC20 {
    using Math for uint256;
    using SignedMath for int256;

    // 代币合约
    WETH public weth;
    IERC20 public token1;

    // 代币储备量
    uint public reserve0;
    uint public reserve1;

    // 事件 
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1);
    event Swap(
        address indexed sender,
        uint256 amountIn,
        address tokenIn,
        uint256 amountOut,
        address tokenOut
        );

    // 构造器，初始化代币地址
    constructor(address _token) ERC20("WETH AMM LP Token", "WETH-AMM") {
        weth = new WETH();
        token1 = IERC20(_token);
    }

    // 添加流动性，转进代币，铸造LP
    // 如果首次添加，铸造的LP数量 = sqrt(amount0 * amount1)
    // 如果非首次，铸造的LP数量 = min(amount0/reserve0, amount1/reserve1)* totalSupply_LP
    // @param amount0Desired 添加的weth数量
    // @param amount1Desired 添加的token1数量
    function addLiquidity(uint256 amount0Desired, uint256 amount1Desired) public returns(uint256 liquidity){
        // 将添加的流动性转入Swap合约，需事先给Swap合约授权
        weth.deposit{value: amount0Desired}();
        weth.transferFrom(msg.sender, address(this), amount0Desired);
        token1.transferFrom(msg.sender, address(this), amount1Desired);
        // 计算添加的流动性
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            // 如果是第一次添加流动性，铸造 L = sqrt(x * y) 单位的LP（流动性提供者）代币
            liquidity = (amount0Desired * amount1Desired).sqrt();
        } else {
            // 如果不是第一次添加流动性，按添加代币的数量比例铸造LP，取两个代币更小的那个比例
            (, uint liquidityL) = amount0Desired.tryMul(_totalSupply);
            (, liquidityL) = liquidityL.tryDiv(reserve0);
            
            (, uint liquidityR) = amount1Desired.tryMul(_totalSupply);
            (, liquidityR) = liquidityR.tryDiv(reserve1);

            liquidity = liquidityL.min(liquidityR);
        }

        // 检查铸造的LP数量
        require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');

        // 更新储备量
        reserve0 = weth.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        // 给流动性提供者铸造LP代币，代表他们提供的流动性
        _mint(msg.sender, liquidity);
        
        emit Mint(msg.sender, amount0Desired, amount1Desired);
    }

    // 移除流动性，销毁LP，转出代币
    // 转出数量 = (liquidity / totalSupply_LP) * reserve
    // @param liquidity 移除的流动性数量
    function removeLiquidity(uint256 liquidity) external returns (uint256 amount0, uint256 amount1) {
        // 获取余额
        uint256 balance0 = weth.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));
        // 按LP的比例计算要转出的代币数量
        uint256 _totalSupply = totalSupply();
        (, amount0) = liquidity.tryMul(balance0);
        (, amount0) = amount0.tryDiv(_totalSupply);

        (, amount1) = liquidity.tryMul(balance1);
        (, amount1) = amount1.tryDiv(_totalSupply);

        // 检查代币数量
        require(amount0 > 0 && amount1 > 0, 'INSUFFICIENT_LIQUIDITY_BURNED');
        // 销毁LP
        _burn(msg.sender, liquidity);
        // 转出代币
        weth.withdraw(amount0);
        payable(msg.sender).transfer(amount0);
        token1.transfer(msg.sender, amount1);
        // 更新储备量
        reserve0 = weth.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Burn(msg.sender, amount0, amount1);
    }

    // 给定一个资产的数量和代币对的储备，计算交换另一个代币的数量
    // 由于乘积恒定
    // 交换前: k = x * y
    // 交换后: k = (x + delta_x) * (y + delta_y)
    // 可得 delta_y = - delta_x * y / (x + delta_x)
    // 正/负号代表转入/转出
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        (, uint amountL) = amountIn.tryMul(reserveOut);
        (, uint amountR) = reserveIn.tryAdd(amountIn);
        (, amountOut) = amountL.tryDiv(amountR);
    }

    // swap代币
    // @param amountIn 用于交换的代币数量
    // @param tokenIn 用于交换的代币合约地址
    // @param amountOutMin 交换出另一种代币的最低数量
    function swap(uint256 amountIn, IERC20 tokenIn, uint256 amountOutMin) external payable returns (uint256 amountOut, IERC20 tokenOut){
        require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
        require(tokenIn == weth || tokenIn == token1, 'INVALID_TOKEN');
        
        uint256 balance0 = weth.balanceOf(address(this));
        uint256 balance1 = token1.balanceOf(address(this));

        if(tokenIn == weth){
            // 如果是weth交换token1
            tokenOut = token1;
            // 计算能交换出的token1数量
            amountOut = getAmountOut(amountIn, balance0, balance1);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // 进行交换
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            weth.deposit{value: amountIn}();
            tokenOut.transfer(msg.sender, amountOut);
        }else{
            // 如果是token1交换weth
            tokenOut = weth;
            // 计算能交换出的token1数量
            amountOut = getAmountOut(amountIn, balance1, balance0);
            require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
            // 进行交换
            tokenIn.transferFrom(msg.sender, address(this), amountIn);
            // tokenOut.transfer(msg.sender, amountOut);
            payable(msg.sender).transfer(amountOut);
            weth.withdraw(amountOut);
        }

        // 更新储备量
        reserve0 = weth.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));

        emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
    }
}
