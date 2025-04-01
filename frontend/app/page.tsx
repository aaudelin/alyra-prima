"use client";

import { type BaseError, useAccount, useReadContract } from "wagmi";
import ErrorComponent from "./components/ErrorComponent";
import NotConnected from "./components/NotConnected";
import { PRIMA_ABI, PRIMA_ADDRESS } from "./contracts";


export default function Home() {
  const { address, isConnected } = useAccount();

  const { data: investorInvoices, error: investorInvoicesError } = useReadContract({
    address: PRIMA_ADDRESS,
    abi: PRIMA_ABI,
    functionName: "getInvestorInvoices",
    account: address,
    args: [],
  }) as { data: BigInt[], error: any };

  console.log(investorInvoices);

  const { data: creditorInvoices, error: creditorInvoicesError } = useReadContract({
    address: PRIMA_ADDRESS,
    abi: PRIMA_ABI,
    functionName: "getCreditorInvoices",
    account: address,
    args: [],
  }) as { data: BigInt[], error: any };

  const { data: debtorInvoices, error: debtorInvoicesError } = useReadContract({
    address: PRIMA_ADDRESS,
    abi: PRIMA_ABI,
    functionName: "getDebtorInvoices",
    account: address,
    args: [],
  }) as { data: BigInt[], error: any };

  if (!isConnected) {
    return <NotConnected />;
  }

  if (investorInvoicesError) {
    return <ErrorComponent error={investorInvoicesError as unknown as BaseError} />;
  }

  if (debtorInvoicesError) {
    return <ErrorComponent error={debtorInvoicesError as unknown as BaseError} />
  }

  if (creditorInvoicesError) {
    return <ErrorComponent error={creditorInvoicesError as unknown as BaseError} />
  }

  return (
    <div>
      <h1 className="text-4xl font-bold">Welcome to Prima</h1>

      <div className="grid grid-cols-3 gap-4 mt-8 mr-8">
        <div className="p-6 bg-white border border-primary rounded-lg shadow-md">
          <p className="text-4xl font-bold">{debtorInvoices?.length || 0}</p>
          <p className="text-gray-600 mt-4">Total invoices as debtor</p>
        </div>

        <div className="p-6 bg-white border border-primary rounded-lg shadow-md">
          <p className="text-4xl font-bold">{investorInvoices?.length || 0}</p>
          <p className="text-gray-600 mt-4">Total invoices as investor</p>
        </div>

        <div className="p-6 bg-white border border-primary rounded-lg shadow-md">
          <p className="text-4xl font-bold">{creditorInvoices?.length || 0}</p>
          <p className="text-gray-600 mt-4">Total invoices as creditor</p>
        </div>
      </div>
    </div>
  );
}
