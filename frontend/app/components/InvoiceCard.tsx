"use client";

import { CreditScore, Invoice, InvoiceStatus } from "@/lib/types";
import {
  useAccount,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import { useState, useEffect } from "react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { PRIMA_ADDRESS } from "../contracts";
import { PRIMA_ABI } from "../contracts";

export default function InvoiceCard({
  invoice,
  refetch,
}: {
  invoice: Invoice;
  refetch?: () => void;
}) {
  const { address } = useAccount();
  const [amountToPay, setAmountToPay] = useState<number>(0);

  const { data: hash, writeContract: acceptInvoice } = useWriteContract();
  const {
    isLoading: isAccepting,
    isSuccess: isAccepted,
    isError: isErrorAccepting,
  } = useWaitForTransactionReceipt({
    hash: hash,
  });

  const onAcceptInvoice = async () => {
    await acceptInvoice({
      address: PRIMA_ADDRESS,
      abi: PRIMA_ABI,
      functionName: "acceptInvoice",
      args: [invoice.tokenId, amountToPay],
      account: address,
    });
  };

  useEffect(() => {
    if (isAccepted) {
      refetch?.();
    }
  }, [isAccepted]);

  return (
    <div className="border rounded-lg p-6 bg-white shadow-sm">
      <div className="flex justify-between items-center mb-4">
        <div className="text-lg font-medium mb-2">{invoice.id}</div>
        <div className="flex items-center gap-2 mb-2">
          <div
            className={`w-6 h-6 rounded-full font-bold flex items-center justify-center ${
              invoice.debtor.creditScore === 0
                ? "bg-green-500"
                : invoice.debtor.creditScore === 1
                ? "bg-emerald-500"
                : invoice.debtor.creditScore === 2
                ? "bg-yellow-500"
                : invoice.debtor.creditScore === 3
                ? "bg-orange-500"
                : invoice.debtor.creditScore === 4
                ? "bg-red-400"
                : "bg-red-600"
            }`}
          >
            {CreditScore[invoice.debtor.creditScore]}
            {invoice.collateral > 0 ? "+" : "-"}
          </div>
        </div>
      </div>
      <div className="text-sm text-gray-500 mb-2">
        {InvoiceStatus[invoice.invoiceStatus]}
      </div>
      <div className="text-sm text-gray-600 mb-4">{invoice.activity}</div>
      <div className="flex flex-col justify-between mb-4">
        <div>
          <div className="text-sm text-gray-500">Débiteur</div>
          <div className="text-sm font-medium">
            {`${invoice.debtor.name.slice(0, 8)}...${invoice.debtor.name.slice(
              -8
            )}`}
          </div>
        </div>
        <div>
          <div className="text-sm text-gray-500">Investisseur</div>
          <div className="text-sm font-medium">
            {`${invoice.investor.name.slice(
              0,
              8
            )}...${invoice.investor.name.slice(-8)}`}
          </div>
        </div>
      </div>
      <div className="flex justify-between items-baseline mb-2">
        <div className="text-sm text-gray-500">
          {new Date(Number(invoice.dueDate)).toLocaleDateString("fr-FR", {
            year: "numeric",
            month: "long",
            day: "numeric",
          })}
        </div>
        <div className="flex flex-col items-end">
          <div className="text-lg font-semibold">
            Total: {invoice.amount.toString()} PGT
          </div>
          <div className="text-sm text-gray-500">
            A payer: {invoice.amountToPay.toString()} PGT
          </div>
          <div className="text-sm text-gray-500">
            Collatéral: {invoice.collateral.toString()} PGT
          </div>
        </div>
      </div>
      {invoice.debtor.name === address && invoice.invoiceStatus === 0 && (
        <div className="flex flex-col gap-2 mt-4 w-full">
          <Input
            type="number"
            placeholder="Montant du collatéral"
            onChange={(e) => setAmountToPay(Number(e.target.value))}
          />
          {isAccepting && <div>Accepter la créance en cours...</div>}
          {isAccepted && <div className="text-green-500">Créance approvée avec succès</div>}
          {isErrorAccepting && <div className="text-red-500">Erreur lors de l'achat de la créance</div>}
          <Button type="button" onClick={onAcceptInvoice}>
            Accepter la créance
          </Button>
        </div>
      )}
    </div>
  );
}
