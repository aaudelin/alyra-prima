"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useConnectModal } from "@rainbow-me/rainbowkit";
import { useEffect } from "react";
import { useAccount } from "wagmi";
export default function Header() {
  const { openConnectModal } = useConnectModal();
  const { isDisconnected } = useAccount();
  useEffect(() => {
    if (isDisconnected) {
      openConnectModal?.();
    }
  }, [isDisconnected, openConnectModal]);

  return (
    <header className="w-full flex justify-end items-center p-4">
      <div>
        <ConnectButton accountStatus="address" chainStatus="icon" />
      </div>
    </header>
  );
}
