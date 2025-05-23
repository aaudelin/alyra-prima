"use client";

import { config } from "@/app/wagmi";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useState } from "react";
import { formatEther, parseEther } from "viem";
import {
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWatchBlockNumber,
  useWriteContract,
  type BaseError,
} from "wagmi";
import ErrorComponent from "../components/ErrorComponent";
import {
  COLLATERAL_ABI,
  COLLATERAL_ADDRESS,
  PRIMA_ABI,
  PRIMA_ADDRESS,
  TOKEN_ABI,
  TOKEN_ADDRESS,
} from "../contracts";


export default function Collateral() {
  const [amount, setAmount] = useState<number>(0);
  const { address } = useAccount();
  const {
    data: hash,
    writeContract: addCollateral,
    error: writeError,
  } = useWriteContract();
  const { writeContract: approve } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess: isConfirmed,
    isError: isError,
  } = useWaitForTransactionReceipt({
    hash: hash,
  });

  const { data: currentCollateral, refetch: refetchCollateral } = useReadContract({
    address: COLLATERAL_ADDRESS,
    abi: COLLATERAL_ABI,
    functionName: "getCollateral",
    args: [address],
  }) as { data: bigint; refetch: () => void };

  useWatchBlockNumber({
    config, 
    onBlockNumber(blockNumber) {
      if (blockNumber) {
        refetchCollateral()
      }
    },
  });

  const onSubmit = async () => {
    const amountMint = parseEther(amount.toString());
    await approve({
      address: TOKEN_ADDRESS,
      abi: TOKEN_ABI,
      functionName: "approve",
      args: [PRIMA_ADDRESS, amountMint],
      account: address,
    });
    await addCollateral({
      address: PRIMA_ADDRESS,
      abi: PRIMA_ABI,
      functionName: "addCollateral",
      args: [amountMint],
      account: address,
    });
  };

  return (
    <div>
      <h1 className="text-4xl font-bold">Collatéral</h1>
      <p>Collatéral actuel: {formatEther(currentCollateral ?? BigInt(0))} PGT</p>
      <div className="mt-8 space-y-4 max-w-2xl">
        <div className="flex items-center gap-2">
          <Input
            className="w-1/2"
            type="number"
            onChange={(e) => setAmount(Number(e.target.value))}
          />
          <p>PGT</p>
        </div>
        {isConfirming && <div>Ajout du collatéral en cours...</div>}
        {isError && (
          <div className="text-red-500">
            Erreur lors de l&apos;ajout du collatéral
          </div>
        )}
        {isConfirmed && (
          <div className="text-green-500">Collatéral ajouté avec succès</div>
        )}
        {writeError && <ErrorComponent error={writeError as BaseError} />}
        <Button type="submit" onClick={onSubmit}>
          Ajouter
        </Button>
      </div>
    </div>
  );
}
