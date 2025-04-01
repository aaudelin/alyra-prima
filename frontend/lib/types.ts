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

enum InvoiceStatus {
    NEW = 0,
    ACCEPTED = 1,
    IN_PROGRESS = 2,
    PAID = 3,
    OVERDUE = 4,
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