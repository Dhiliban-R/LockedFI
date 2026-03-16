"use client";
import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { ShieldCheck, Wallet, Lock, AlertCircle, Send, RefreshCw } from "lucide-react";
import { VAULT_ADDRESS, VAULT_ABI } from "../constants/vault";

export default function LockedFIDashboard() {
  const [account, setAccount] = useState<string | null>(null);
  const [hasBadge, setHasBadge] = useState<boolean>(false);
  const [amount, setAmount] = useState<string>("0.05");
  const [status, setStatus] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);

  // Use a direct RPC provider for stable READS (Fixes BAD_DATA)
  const getReadProvider = () => {
    return new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  };

  const connectWallet = async () => {
    if (typeof window.ethereum !== "undefined") {
      try {
        const accounts = await window.ethereum.request({ method: "eth_requestAccounts" });
        setAccount(accounts[0]);
        checkBadgeStatus();
      } catch (err) {
        console.error("Connection failed", err);
        alert("Wallet connection failed. Please try again.");
      }
    } else {
      alert("No Web3 wallet detected. Please make sure Brave Wallet is enabled in Brave Settings.\n\nTo add local network in Brave Wallet:\n1. Open Brave Wallet\n2. Add Network\n3. Name: Localhost\n4. RPC URL: http://127.0.0.1:8545\n5. Chain ID: 31337");
    }
  };

  const checkBadgeStatus = async () => {
    setLoading(true);
    try {
      const provider = getReadProvider();
      const contract = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, provider);
      const badgeStatus = await contract.hasHighIncomeBadge();
      setHasBadge(badgeStatus);
    } catch (err) {
      console.error("Error checking badge status", err);
    } finally {
      setLoading(false);
    }
  };

  const handleWithdraw = async () => {
    if (!account) return alert("Connect wallet first!");
    setStatus("Initiating Dual-Signature Flow...");

    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      
      // 1. Create a unique hash for this withdrawal
      const txHash = ethers.id("withdraw_" + Date.now());
      
      // 2. OWNER SIGNATURE: Brave Wallet pops up
      setStatus("Step 1: Signing as Owner...");
      const ownerSig = await signer.signMessage(ethers.getBytes(txHash));

      // 3. AI SIGNATURE: Requesting from our Bridge API
      setStatus("Step 2: Requesting AI Guardian Approval...");
      const response = await fetch("/api/approve", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          txContext: `User ${account} wants to withdraw ${amount} ETH.`,
          userOpHash: txHash
        })
      });
      const aiData = await response.json();

      if (!aiData.approved) {
        setStatus("❌ AI REJECTED: " + (aiData.decision || aiData.error || "Unknown reason"));
        return;
      }

      // 4. BUNDLE SIGNATURES: Glue 65 bytes + 65 bytes = 130 bytes
      const bundledSig = ownerSig + aiData.signature.slice(2); 
      console.log("Bundled Signature:", bundledSig);
      
      // 5. SUBMIT TO BLOCKCHAIN
      setStatus("Step 3: Submitting to Smart Vault...");
      const contract = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, signer);
      
      const tx = await contract.execute(account, ethers.parseEther(amount), "0x");
      setStatus("Step 4: Waiting for Confirmation...");
      await tx.wait();

      setStatus("✅ SUCCESS: Funds Released!");
    } catch (err: any) {
      console.error(err);
      setStatus("❌ Error: " + (err.reason || err.message));
    }
  };

  useEffect(() => {
    checkBadgeStatus();
    if (typeof window !== "undefined" && window.ethereum) {
      window.ethereum.on("accountsChanged", (accounts: string[]) => {
        setAccount(accounts[0] || null);
        checkBadgeStatus();
      });
    }
  }, []);

  return (
    <main className="min-h-screen bg-slate-950 text-white p-8 font-sans">
      <div className="max-w-4xl mx-auto">
        <header className="flex justify-between items-center mb-12 border-b border-slate-800 pb-6">
          <div className="flex items-center gap-4">
            <h1 className="text-3xl font-bold tracking-tighter text-blue-500">LOCKED<span className="text-white">FI</span>🧐</h1>
            <button onClick={checkBadgeStatus} className="p-2 text-slate-400 hover:text-white transition">
              <RefreshCw size={20} className={loading ? "animate-spin" : ""} />
            </button>
          </div>
          <button onClick={connectWallet} className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded-lg transition">
            <Wallet size={20} />
            {account ? `${account.slice(0, 6)}...${account.slice(-4)}` : "Connect Wallet"}
          </button>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
          <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
            <div className="flex justify-between items-start mb-4">
              <h2 className="text-xl font-semibold">ZK-Income Status</h2>
              {hasBadge ? <ShieldCheck className="text-green-400" size={32} /> : <Lock className="text-slate-600" size={32} />}
            </div>
            <p className="text-slate-400">{hasBadge ? "Verified. High-value transactions enabled." : "Proof Required for > 0.1 ETH."}</p>
          </div>

          <div className="bg-slate-900 border border-slate-800 p-6 rounded-2xl">
            <div className="flex justify-between items-start mb-4">
              <h2 className="text-xl font-semibold">AI Guardian</h2>
              <AlertCircle className="text-blue-400" size={32} />
            </div>
            <p className="text-slate-400">Monitoring Active. Risk Analysis Enabled.</p>
          </div>
        </div>

        <div className="bg-slate-900 border border-slate-800 p-8 rounded-2xl">
          <h2 className="text-2xl font-bold mb-6">Withdraw Funds</h2>
          <div className="flex gap-4 mb-6">
            <input 
              type="number" value={amount} onChange={(e) => setAmount(e.target.value)}
              className="bg-slate-950 border border-slate-800 rounded-xl px-4 py-3 flex-1 outline-none focus:border-blue-500 text-white"
              step="0.01"
            />
            <button onClick={handleWithdraw} className="bg-blue-600 hover:bg-blue-700 px-8 py-3 rounded-xl font-bold flex items-center gap-2 transition active:scale-95">
              <Send size={18} /> Withdraw
            </button>
          </div>
          {status && (
            <div className="p-4 bg-slate-950 border border-slate-800 rounded-xl text-sm font-mono text-blue-300">
              {status}
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
