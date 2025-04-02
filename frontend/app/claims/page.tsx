"use client";

import ErrorComponent from "@/app/components/ErrorComponent";
import InvoiceCard from "@/app/components/InvoiceCard";
import { PRIMA_ABI, PRIMA_ADDRESS } from "@/app/contracts";
import { Invoice } from "@/lib/types";
import { useEffect, useState } from "react";
import {
  type BaseError,
  useAccount,
  useChainId,
  usePublicClient,
  useReadContract,
} from "wagmi";

export default function Claims() {
  const { address } = useAccount();
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const chainId = useChainId();

  const publicClient = usePublicClient({
    chainId: chainId,
  });

  const { data: invoicesIds, error: invoicesIdsError } = useReadContract({
    address: PRIMA_ADDRESS,
    abi: PRIMA_ABI,
    functionName: "getCreditorInvoices",
    account: address,
  }) as { data: bigint[]; error: any };

  if (invoicesIdsError) {
    return <ErrorComponent error={invoicesIdsError as unknown as BaseError} />;
  }

  async function fetchInvoices() {
    try {
      if (invoicesIds) {
        const invoicesToAdd: Invoice[] = [];
        for (const invoiceId of invoicesIds) {
          const newInvoice = await publicClient?.readContract({
            abi: PRIMA_ABI,
            address: PRIMA_ADDRESS,
            functionName: "getInvoice",
            args: [invoiceId],
            account: address,
          });
          invoicesToAdd.push(newInvoice as Invoice);
        }
        await setInvoices([...invoicesToAdd]);
      }
    } catch (error) {
      console.error("Error fetching invoices", error);
    }
  }

  useEffect(() => {
    fetchInvoices();
  }, [invoicesIds]);

  return (
    <div>
      <h1 className="text-4xl font-bold">Mes créances</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-8">
        {invoices.map((invoice, index) => (
          <InvoiceCard key={index} invoice={invoice} />
        ))}
      </div>
    </div>
  );
}
