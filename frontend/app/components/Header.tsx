"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { useEffect } from "react";
import { useAccount, useBalance, useReadContract, useWatchBlockNumber } from "wagmi";
import { formatEther } from "viem";
import { TOKEN_ABI, TOKEN_ADDRESS } from "@/app/contracts";
import { config } from "@/app/wagmi";


export default function Header() {
  const { openConnectModal } = useConnectModal();
  const { isDisconnected, isConnected, address } = useAccount();

  const { data: balance, refetch: refetchBalance } = useReadContract({
    address: TOKEN_ADDRESS,
    abi: TOKEN_ABI, 
    functionName: "balanceOf",
    args: [address],
  }) as { data: bigint; refetch: () => void };

  useWatchBlockNumber({
    config, 
    onBlockNumber(blockNumber) {
      refetchBalance()
    },
  })

  useEffect(() => {
    if (isDisconnected) {
      openConnectModal?.();
    }
  }, [isDisconnected, openConnectModal]);

  return (
    <header className="w-full flex justify-between items-center py-4">
      {isConnected && (
        <div className="text-md border border-primary rounded-lg px-4 py-2">
          Balance: {formatEther(balance ?? BigInt(0))} PGT
        </div>
      )}
      <div>
        <ConnectButton accountStatus="address" chainStatus="icon" />
      </div>
    </header>
  );
}
