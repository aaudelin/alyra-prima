"use client";

import { PRIMA_ABI, PRIMA_ADDRESS } from "@/app/contracts";
import { Invoice } from "@/lib/types";
import { useEffect, useState } from "react";
import {
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

  const { data: invoicesIds } = useReadContract({
    address: PRIMA_ADDRESS,
    abi: PRIMA_ABI,
    functionName: "getCreditorInvoices",
    account: address,
  }) as { data: bigint[] };

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
          <div key={index} className="border rounded-lg p-6 bg-white shadow-sm">
            <div className="text-lg font-medium mb-2">{invoice.id}</div>
            <div className="text-sm text-gray-600 mb-4">{invoice.activity}</div>
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
                  {invoice.amount.toString()} PGT
                </div>
                <div className="text-sm text-gray-500">
                  {invoice.amountToPay.toString()} PGT
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
