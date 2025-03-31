"use client";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { CreditScore, Company } from "@/lib/types";
import { useAccount } from "wagmi";

export default function NewClaim() {
  const { address } = useAccount();
  const creditor: Company = {
    name: address as `0x${string}`,
    creditScore: Math.floor(Math.random() * 5) + 1,
  };

  return (
    <div>
      <h1 className="text-4xl font-bold">Nouvelle créance</h1>

      <form className="mt-8 space-y-6 max-w-2xl">
        <div className="space-y-4">
          <div>
            <label htmlFor="id" className="block text-sm font-medium">
              Identifiant de la créance
            </label>
            <Input type="text" id="id" name="id" />
          </div>

          <div>
            <label htmlFor="activity" className="block text-sm font-medium">
              Activité
            </label>
            <Input type="text" id="activity" name="activity" />
          </div>

          <div>
            <label htmlFor="country" className="block text-sm font-medium">
              Pays
            </label>
            <Input type="text" id="country" name="country" />
          </div>

          <div>
            <label htmlFor="dueDate" className="block text-sm font-medium">
              Date d'échéance
            </label>
            <Input type="date" id="dueDate" name="dueDate" />
          </div>

          <div>
            <label htmlFor="amount" className="block text-sm font-medium">
              Montant
            </label>
            <Input type="number" id="amount" name="amount" />
          </div>

          <div>
            <label htmlFor="amountToPay" className="block text-sm font-medium">
              Montant à payer
            </label>
            <Input type="number" id="amountToPay" name="amountToPay" />
          </div>

          <div className="space-y-4">
            <h3 className="text-lg font-medium">Débiteur</h3>
            <div>
              <label htmlFor="debtorName" className="block text-sm font-medium">
                Adresse Ethereum
              </label>
              <Input type="text" id="debtorName" name="debtorName" />
            </div>
            <div>
              <label
                htmlFor="debtorScore"
                className="block text-sm font-medium"
              >
                Note de crédit (this value is disabled and random for the POC)
              </label>
              <Input
                type="text"
                id="debtorScore"
                name="debtorScore"
                disabled
                defaultValue={CreditScore[Math.floor(Math.random() * 5) + 1]}
              />
            </div>
          </div>
        </div>

        <Button
          type="submit"
        >
          Créer la créance
        </Button>
      </form>
    </div>
  );
}
