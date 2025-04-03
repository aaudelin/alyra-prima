"use client";

import {
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
  type BaseError,
} from "wagmi";
import {
  PRIMA_ABI,
  PRIMA_ADDRESS,
  TOKEN_ABI,
  TOKEN_ADDRESS,
} from "../contracts";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { formatEther, parseEther } from "viem";
import ErrorComponent from "../components/ErrorComponent";

export default function Collateral() {
  const [amount, setAmount] = useState<number>(0);
  const { address } = useAccount();
  const {
    data: hash,
    writeContract: addCollateral,
    error: writeError,
  } = useWriteContract();
  const {
    data: hashApprove,
    writeContract: approve,
    error: writeErrorApprove,
  } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess: isConfirmed,
    isError: isError,
  } = useWaitForTransactionReceipt({
    hash: hash,
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
            Erreur lors de l'ajout du collatéral
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
