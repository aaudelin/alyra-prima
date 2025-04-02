import { CreditScore, Invoice, InvoiceStatus } from "@/lib/types";

export default function InvoiceCard({ invoice }: { invoice: Invoice }) {
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
                  {CreditScore[invoice.debtor.creditScore]}{invoice.collateral > 0 ? "+": "-"}
                </div>
              </div>
            </div>
            <div className="text-sm text-gray-500 mb-2">{InvoiceStatus[invoice.invoiceStatus]}</div>
            <div className="text-sm text-gray-600 mb-4">{invoice.activity}</div>
            <div className="flex flex-col justify-between mb-4">
              <div>
                <div className="text-sm text-gray-500">Débiteur</div>
                <div className="text-sm font-medium">
                  {`${invoice.debtor.name.slice(
                    0,
                    8
                  )}...${invoice.debtor.name.slice(-8)}`}
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
                  {invoice.amount.toString()} PGT
                </div>
                <div className="text-sm text-gray-500">
                  {invoice.amountToPay.toString()} PGT
                </div>
              </div>
            </div>
          </div>
    )
}