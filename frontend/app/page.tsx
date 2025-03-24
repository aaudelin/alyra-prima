"use client";

import { Button } from "@/components/ui/button";
import { useAccount } from "wagmi";
export default function Home() {
  const { address, isConnected } = useAccount();

  if (!isConnected) {
    return <div></div>;
  }
  return (
    <div>
      <h1>Prima</h1>
      <Button>Click me</Button>
    </div>
  );
}
