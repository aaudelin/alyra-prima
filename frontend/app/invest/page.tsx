"use client";

import InvoiceCard from "@/app/components/InvoiceCard";
import { INVOICE_ADDRESS, PRIMA_ABI, PRIMA_ADDRESS } from "@/app/contracts";
import { Invoice } from "@/lib/types";
import { useEffect, useState } from "react";
import { parseAbiItem } from "viem";
import {
    useAccount,
    useChainId,
    usePublicClient
} from "wagmi";

export default function Invest() {
  const { address } = useAccount();
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const chainId = useChainId();
  const publicClient = usePublicClient({
    chainId: chainId,
  });

  async function fetchInvoices() {
    const invoicesToAdd: Invoice[] = [];

    const approvedEvents = await publicClient?.getLogs({
      address: INVOICE_ADDRESS,
      event: parseAbiItem(
        "event InvoiceNFT_StatusChanged(uint256 tokenId, uint8 newStatus)"
      ),
      args: {
        newStatus: 1,
      },
      fromBlock: "earliest",
      toBlock: "latest",
    });

    if (approvedEvents) {
      for (const event of approvedEvents) {
        const tokenId = event.args.tokenId;
        const newInvoice = (await publicClient?.readContract({
          abi: PRIMA_ABI,
          address: PRIMA_ADDRESS,
          functionName: "getInvoice",
          args: [tokenId],
          account: address,
        })) as Invoice;
        newInvoice.tokenId = Number(tokenId);
        if (newInvoice.invoiceStatus === 1 && newInvoice.debtor.name !== address && newInvoice.creditor.name !== address) {
          invoicesToAdd.push(newInvoice);
        }
      }
      await setInvoices([...invoicesToAdd]);
    }
  }

  useEffect(() => {
    if (address) {
      fetchInvoices();
    }
  }, [address]);

  return (
    <div>
      <h1 className="text-4xl font-bold">Investir</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mt-8">
        {invoices.map((invoice, index) => (
          <InvoiceCard refetch={fetchInvoices} key={index} invoice={invoice} />
        ))}
      </div>
    </div>
  );
}
