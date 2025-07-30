import { createWalletClient, http } from 'viem'
import { sepolia } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import dotenv from 'dotenv'
import * as solc from 'solc'
import fs from 'fs'
import path from 'path'
import { createPublicClient } from 'viem'
import { fileURLToPath } from 'url';

dotenv.config()

// 1. 编译合约
const sourcePath = path.resolve(__dirname, 'contracts', 'esRNT.sol');
const source = fs.readFileSync(sourcePath, 'utf8')

const input = {
  language: 'Solidity',
  sources: {
    'esRNT.sol': { content: source },
  },
  settings: {
    outputSelection: {
      '*': {
        '*': ['abi', 'evm.bytecode.object'],
      },
    },
  },
}

const output = JSON.parse(solc.compile(JSON.stringify(input)))
const contract = output.contracts['esRNT.sol']['esRNT']
const abi = contract.abi
const bytecode = ('0x' + contract.evm.bytecode.object) as `0x${string}`;

// 2. 创建钱包和客户端
const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`)

const client = createWalletClient({
  account,
  chain: sepolia,
  transport: http(),
})

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
})

// 3. 部署合约
async function deploy() {
  const hash = await client.deployContract({
    abi,
    bytecode,
    account,
    args: [],
  })
  console.log('Deploy tx hash:', hash)

  const receipt = await publicClient.waitForTransactionReceipt({ hash })
  console.log('Contract deployed at:', receipt.contractAddress)
}

deploy()
