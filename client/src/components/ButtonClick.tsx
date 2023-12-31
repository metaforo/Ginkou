import { useAccount, useConnectors } from '@starknet-react/core'
import { useCallback, useMemo, useState, useEffect } from 'react'
import { Contract, uint256, CallData, RawArgs, Call, num } from 'starknet'
import { Wrap } from '@bibliothecadao/instaswap-core'
import { FeeAmount,SwapDirection } from '@bibliothecadao/instaswap-core'
import { Provider, constants, cairo } from "starknet"


const ButtonClick = () => {
  const [lowerBound, setLowerBound] = useState(0);
  const [upperBound, setUpperBound] = useState(0);
  const { address, account } = useAccount()
  const [balance, setBalance] = useState("0");
  const [currentPrice, setCurrentPrice] = useState(0);
  const [mintAmount, setMintAmount] = useState(0);
  const [erc1155Amount, setAddLiquidityERC1155Amount] = useState(0);
  const [ethAmount, setAddLiquidityEthAmount] = useState(0);
  const [erc1155AmountForSwap, setERC1155AmountForSwap] = useState(0);
  const [erc20AmountForSwap, setERC20AmountForSwap] = useState(0);
  const [wGoldForSwap, setWGoldForSwap] = useState(0);


    const erc1155_address = useMemo(() => "0x03467674358c444d5868e40b4de2c8b08f0146cbdb4f77242bd7619efcf3c0a6", [])

    const  eth_address  = useMemo(() => "0x06044d3038dee0011c54e38d3cf53b1ff082cb9af3ffb90a741df3ddb05b152d", [])
    const  werc20_address = useMemo(() => "0x0734ca91d8ab5805855536572f85f49e93049edb9914402018cd33d8f46e52bc", [])

  const ekubo_position_address = useMemo(() => "0x73fa8432bf59f8ed535f29acfd89a7020758bda7be509e00dfed8a9fde12ddc", [])
  const ekubo_core_address = useMemo(() => "0x031e8a7ab6a6a556548ac85cbb8b5f56e8905696e9f13e9a858142b8ee0cc221", [])
  const avnu_address = useMemo(() => "0x07e36202ace0ab52bf438bd8a8b64b3731c48d09f0d8879f5b006384c2f35032", [])
  const simple_swapper = useMemo(() => "0x064f7ed2dc5070133ae8ccdf85f01e82507facbe5cdde456e1418e3901dc51a0", [])
    const quoter = useMemo(() => "0x042aa743335663ed9c7b52b331ab7f81cc8d65280d311506653f9b5cc22be7cb", [])
  const provider = new Provider({ sequencer: { network: constants.NetworkName.SN_GOERLI } });


  const config = {
      erc1155Address: erc1155_address,
      werc20Address:werc20_address,
      erc20Address:eth_address,
      ekuboPositionAddress:ekubo_position_address,
      ekuboCoreAddress:ekubo_core_address,
      quoterAddress:quoter,
      provider:provider,
      account:account
  }


    const wrap = new Wrap(config);

  const getERC1155Balance = useCallback(async () => {
    if (!address) return;
    const b = await Wrap.getERC1155Balance(address, 1);
    setBalance(b.toString());
  }, [address, erc1155_address]);



const getCurrentPrice = useCallback(async () => {
    if (!address) return;
    const  p = await wrap.quoteSingle(FeeAmount.LOWEST, werc20_address, BigInt(10** 7));
    const realPrice = p / (10 ** 7);
    setCurrentPrice(realPrice);
}, [address, erc1155_address, account]);

useEffect(() => {
getERC1155Balance();
const interval = setInterval(() => {
  getERC1155Balance();
}, 10000);
return () => clearInterval(interval);
}, [getERC1155Balance]);

// useEffect(() => {
//     getCurrentPrice();
//     const interval = setInterval(() => {
//         getCurrentPrice();
//     }, 3000);
//     return () => clearInterval(interval);
// }, [getCurrentPrice]);




const handleSwap = useCallback(async () => {
    if (!account) return;
    // debugger;
    const params = {
        amountIn:  wGoldForSwap* (10 **18),
        minERC20AmountOut: 1313331313,
        simpleSwapperAddress: simple_swapper,
        userAddress: account.address,
        fee:  FeeAmount.LOWEST,
        slippage: 0.99,
    }

    const { transaction_hash } = await wrap.swapSimple(SwapDirection.ERC20_TO_ERC1155,params);
    console.log(transaction_hash);
}, [account, wGoldForSwap, currentPrice, avnu_address]);





  const mayInitializePool = useCallback(async () => {
    const initialize_tick = {
      mag: 0n,
      sign: false
    }

    const { transaction_hash } = await wrap.mayInitializePool(FeeAmount.LOWEST, initialize_tick);
    console.log(transaction_hash);
  }, [account, lowerBound, upperBound])

  const mintERC1155Token = useCallback(async () => {
    if (!address) return;
    const call: Call = {
      contractAddress: Wrap.ERC1155Contract.address,
      entrypoint: "mint",
      calldata: CallData.compile({
          to: address,
          id: cairo.uint256(1),
          amount: cairo.uint256(mintAmount),
      })
  }
    account?.execute(
      call
    )
  }, [address, erc1155_address, getERC1155Balance, mintAmount]);

    const handleAddLiquidity = useCallback(async () => {

        if (!account) return;

        const params = {
            erc1155Amount: erc1155Amount,
            erc20Amount: ethAmount * (10 **18),
            fee: FeeAmount.LOWEST,
            lowerPrice: lowerBound,
            upperPrice:upperBound,
        };

        //add liquidity
        const { transaction_hash } = await wrap.addLiquidity(params);
        console.log(transaction_hash);

    }, [account, lowerBound, upperBound, ethAmount, erc1155Amount])

  return (
    <div>

      <div>
          <p>Current Price : 1 WGold =  {currentPrice} WSliver </p>
      </div>

        <div>
            <button onClick={mayInitializePool}>may initialize pool</button>
        </div>

        <div>
            <h3> Add Liquidity </h3>
        </div>
        <div>
            <label htmlFor="lowerBound">Lower Price For ETH/ERC1155:</label>
            <input type="number" id="lowerBound" value={lowerBound} onChange={(e) => setLowerBound(parseFloat(e.target.value))} />
        </div>
        <div>
            <label htmlFor="upperBound">Upper Price For ETH/ERC1155:</label>
            <input type="number" id="upperBound" value={upperBound} onChange={(e) => setUpperBound(parseFloat(e.target.value))} />
        </div>
        <div>
            <label htmlFor="eth amount">eth Amount:</label>
            <input type="number" id="erc20 amount" value={ethAmount} onChange={(e) => setAddLiquidityEthAmount(parseFloat(e.target.value))} />
        </div>
        <div>
            <label htmlFor="erc1155 amount">ERC1155 amount:</label>
            <input type="number" id="erc1155 amount" value={erc1155Amount} onChange={(e) => setAddLiquidityERC1155Amount(parseFloat(e.target.value))} />
        </div>
        <div>
            <button onClick={handleAddLiquidity}>add liquidity</button>
        </div>



        <div>
            <h3> Swap From WGold to WSliver By SimpleSwapper</h3>
        </div>
        <div>
            <label htmlFor="erc20 amount">WGold amount:</label>
            <input type="number" id="wGold amount" value={wGoldForSwap} onChange={(e) => setWGoldForSwap(parseFloat(e.target.value))} />
        </div>
        <div>
            <button onClick={handleSwap}>swap</button>
        </div>


    </div>
  )
}

export default ButtonClick