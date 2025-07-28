import { useEffect, useState } from "react";
import { type Hex, createPublicClient, http, createWalletClient, custom, formatEther, parseEther } from "viem";
import { sepolia } from "viem/chains";

import tokenBankJson from "../src/abi/TokenBank.json"; 
import tokenJson from "../src/abi/Token.json";
import { waitForTransactionReceipt } from "viem/actions";

//ABI
const tokenBankAbi = tokenBankJson["contracts"]["src/TokenBank.sol:TokenBank"].abi;
const tokenAbi = tokenJson["contracts"]["src/Token.sol:BaseERC20"].abi;

//环境变量
const tokenBankAddress = import.meta.env.VITE_TOKENBANK_ADDRESS as `0x${string}`;
const tokenAddress = import.meta.env.VITE_TOKEN_ADDRESS as `0x${string}`;

//公共客户端：读操作
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
});

declare global {
  interface Window {
    ethereum?: any;
  }
}

function App() {
  const [account, setAccount] = useState<`0x${string}` | null>(null);
  const [walletBalance, setWalletBalance] = useState("0");
  const [bankBalance, setBankBalance] = useState("0");
  const [inputAmount, setInputAmount] = useState("");
  

  // 钱包客户端：写操作
  const walletClient = account? createWalletClient({
    account,
    chain:sepolia,
    transport:custom(window.ethereum)
  }):null;

  // 连接钱包
  const connectWallet = async () => {
    if (!window.ethereum) return alert("请安装 MetaMask");
    const [address] = await window.ethereum.request({ method: "eth_requestAccounts" });
    setAccount(address);
  };

  //读取erc20合约和bank合约的账户余额
  const fetchBalance = async()=>{
    if(!account) return;
    try{
      const walletBal = await publicClient.readContract({
        address: tokenAddress,
        abi: tokenAbi,
        functionName:"balanceOf",
        args: [account]
      });

      const bankBal = await publicClient.readContract({
        address: tokenBankAddress,
        abi: tokenBankAbi,
        functionName: "balances",
        args: [account]
      });

      setWalletBalance(formatEther(walletBal as bigint));
      setBankBalance(formatEther(bankBal as bigint));
    } catch (err){
      console.error("读取余额失败", err)
    }
  };

  //存款操作
  const handleDeposit = async() =>{
    if(!walletClient || !account) return alert("请先链接钱包");
    if(!inputAmount || isNaN(Number(inputAmount)) || Number(inputAmount)<=0){
      alert("请输入正确的存款金额");
      return;
    }

    const amount = parseEther(inputAmount);
    
    try{
      //1.Approve
      const approveHash = await walletClient.writeContract({
        address: tokenAddress,
        abi: tokenAbi,
        functionName: "approve",
        args: [tokenBankAddress, amount],
      });

      // receipt
      const receiptApprove = await publicClient.waitForTransactionReceipt({
          hash: approveHash as Hex,
      })

      console.log("Approve 成功:", receiptApprove);

      //2.Deposit
      const depositHash = await walletClient.writeContract({
        address:tokenBankAddress,
        abi: tokenBankAbi,
        functionName: "deposit",
        args: [amount],
      });

      const receiptDeposit = await publicClient.waitForTransactionReceipt({
        hash: depositHash as Hex,
      });

      console.log(receiptDeposit);
      setInputAmount("");
      fetchBalance();
    }catch(err){
      console.error("存款失败", err);
    }
  };
  

  // withdraw
  const handleWithdraw = async() => {
    if(!walletClient || !account) return alert ("请先链接钱包");
    if(!inputAmount || isNaN(Number(inputAmount)) || Number(inputAmount) <= 0){
      alert("请输入正确的取款金额");
      return;
    }

    const amount = parseEther(inputAmount);
    try{
      const withdrawHash = await walletClient.writeContract({
        address: tokenBankAddress,
        abi: tokenBankAbi,
        functionName: "withdraw",
        args: [amount],
      });

      const receiptWithdraw = await publicClient.waitForTransactionReceipt({
        hash: withdrawHash as Hex,
      });

      console.log(receiptWithdraw);
      setInputAmount("");
      fetchBalance();
    }catch (err){
      console.error("取款失败",err);
    }
  };

  useEffect(() => {
    if (account) {
      fetchBalance();
    }
  }, [account]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 p-6">
      <div className="bg-white p-8 rounded-xl shadow-md w-full max-w-md space-y-6">
        <h1 className="text-3xl font-bold text-center mb-4">🪙 TokenBank DApp</h1>

        <button
          onClick={connectWallet}
          className="w-full py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
        >
          {account
            ? `已连接：${account.slice(0, 6)}...${account.slice(-4)}`
            : "连接钱包"}
        </button>

        <div className="text-center space-y-2">
          <p>钱包余额: <span className="font-mono">{walletBalance}</span> DRG</p>
          <p>银行余额: <span className="font-mono">{bankBalance}</span> DRG</p>
        </div>

        <input
          type="number"
          min="0"
          step="any"
          placeholder="输入存取金额"
          value={inputAmount}
          onChange={(e) => setInputAmount(e.target.value)}
          className="w-full border border-gray-300 rounded-lg px-3 py-2"
        />

        <div className="flex space-x-4">
          <button
            onClick={handleDeposit}
            className="flex-1 py-2 bg-green-500 text-white rounded-lg hover:bg-green-600 transition"
          >
            存款
          </button>

          <button
            onClick={handleWithdraw}
            className="flex-1 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition"
          >
            取款
          </button>
        </div>
      </div>
    </div>
  );
}

export default App;
