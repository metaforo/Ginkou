import { useBlock } from '@starknet-react/core'
import WalletBar from './components/WalletBar'
import { BlockNumber, BlockTag } from 'starknet';

function App() {
  const latestBlockNumber: BlockNumber = BlockTag.latest;
  const { data, isLoading, isError } = useBlock({
    refetchInterval: 3000,
    blockIdentifier: latestBlockNumber,
  })

  return (
    <main>
      <div>
        {isLoading
          ? 'Loading...'
          : isError
          ? 'Error while fetching the latest block hash'
          : `Latest block hash: ${data?.block_hash}`}
      </div>
      <WalletBar />
    </main>
  )
}

export default App
