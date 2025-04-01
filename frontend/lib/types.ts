export enum CreditScore {
    A = 1,
    B = 2,
    C = 3,
    D = 4,
    E = 5,
};

export type Company = {
    name: `0x${string}`;
    creditScore: number;
};

export enum InvoiceStatus {
    "Nouvelle" = 0,
    "Acceptée" = 1,
    "EnCours" = 2,
    "Payée" = 3,
    "En Retard" = 4,
}

export type Invoice = {
    id: string;
    activity: string;
    country: string;
    dueDate: number;
    amount: number;
    amountToPay: number;
    collateral: number;
    debtor: Company;
    creditor: Company;
    investor: Company;
    invoiceStatus: InvoiceStatus;
}