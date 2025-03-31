export const PRIMA_ADDRESS = process.env.NEXT_PUBLIC_PRIMA_ADDRESS as `0x${string}`;
export const TOKEN_ADDRESS = process.env.NEXT_PUBLIC_TOKEN_ADDRESS as `0x${string}`;
export const INVOICE_ADDRESS = process.env.NEXT_PUBLIC_INVOICE_ADDRESS as `0x${string}`;
export const COLLATERAL_ADDRESS = process.env.NEXT_PUBLIC_COLLATERAL_ADDRESS as `0x${string}`;

export const TOKEN_ABI = [
  { type: "constructor", inputs: [], stateMutability: "nonpayable" },
  {
    type: "function",
    name: "allowance",
    inputs: [
      { name: "owner", type: "address", internalType: "address" },
      { name: "spender", type: "address", internalType: "address" },
    ],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "approve",
    inputs: [
      { name: "spender", type: "address", internalType: "address" },
      { name: "value", type: "uint256", internalType: "uint256" },
    ],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "balanceOf",
    inputs: [{ name: "account", type: "address", internalType: "address" }],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "decimals",
    inputs: [],
    outputs: [{ name: "", type: "uint8", internalType: "uint8" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "mint",
    inputs: [
      { name: "to", type: "address", internalType: "address" },
      { name: "amount", type: "uint256", internalType: "uint256" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "name",
    inputs: [],
    outputs: [{ name: "", type: "string", internalType: "string" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "symbol",
    inputs: [],
    outputs: [{ name: "", type: "string", internalType: "string" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "totalSupply",
    inputs: [],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "transfer",
    inputs: [
      { name: "to", type: "address", internalType: "address" },
      { name: "value", type: "uint256", internalType: "uint256" },
    ],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "transferFrom",
    inputs: [
      { name: "from", type: "address", internalType: "address" },
      { name: "to", type: "address", internalType: "address" },
      { name: "value", type: "uint256", internalType: "uint256" },
    ],
    outputs: [{ name: "", type: "bool", internalType: "bool" }],
    stateMutability: "nonpayable",
  },
  {
    type: "event",
    name: "Approval",
    inputs: [
      {
        name: "owner",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "spender",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "event",
    name: "Transfer",
    inputs: [
      {
        name: "from",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "to",
        type: "address",
        indexed: true,
        internalType: "address",
      },
      {
        name: "value",
        type: "uint256",
        indexed: false,
        internalType: "uint256",
      },
    ],
    anonymous: false,
  },
  {
    type: "error",
    name: "ERC20InsufficientAllowance",
    inputs: [
      { name: "spender", type: "address", internalType: "address" },
      { name: "allowance", type: "uint256", internalType: "uint256" },
      { name: "needed", type: "uint256", internalType: "uint256" },
    ],
  },
  {
    type: "error",
    name: "ERC20InsufficientBalance",
    inputs: [
      { name: "sender", type: "address", internalType: "address" },
      { name: "balance", type: "uint256", internalType: "uint256" },
      { name: "needed", type: "uint256", internalType: "uint256" },
    ],
  },
  {
    type: "error",
    name: "ERC20InvalidApprover",
    inputs: [{ name: "approver", type: "address", internalType: "address" }],
  },
  {
    type: "error",
    name: "ERC20InvalidReceiver",
    inputs: [{ name: "receiver", type: "address", internalType: "address" }],
  },
  {
    type: "error",
    name: "ERC20InvalidSender",
    inputs: [{ name: "sender", type: "address", internalType: "address" }],
  },
  {
    type: "error",
    name: "ERC20InvalidSpender",
    inputs: [{ name: "spender", type: "address", internalType: "address" }],
  },
];

export const PRIMA_ABI = [
  {
    type: "constructor",
    inputs: [
      {
        name: "invoiceNFTAddress",
        type: "address",
        internalType: "address",
      },
      {
        name: "collateralAddress",
        type: "address",
        internalType: "address",
      },
      {
        name: "primaTokenAddress",
        type: "address",
        internalType: "address",
      },
    ],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "acceptInvoice",
    inputs: [
      { name: "tokenId", type: "uint256", internalType: "uint256" },
      {
        name: "collateralAmount",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "addCollateral",
    inputs: [
      {
        name: "collateralAmount",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "collateral",
    inputs: [],
    outputs: [
      { name: "", type: "address", internalType: "contract Collateral" },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "computeAmounts",
    inputs: [
      { name: "amount", type: "uint256", internalType: "uint256" },
      {
        name: "debtorCreditScore",
        type: "uint8",
        internalType: "enum InvoiceNFT.CreditScore",
      },
    ],
    outputs: [
      {
        name: "minimumAmount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "maximumAmount",
        type: "uint256",
        internalType: "uint256",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "generateInvoice",
    inputs: [
      {
        name: "invoiceParams",
        type: "tuple",
        internalType: "struct InvoiceNFT.InvoiceParams",
        components: [
          { name: "id", type: "string", internalType: "string" },
          { name: "activity", type: "string", internalType: "string" },
          { name: "country", type: "string", internalType: "string" },
          { name: "dueDate", type: "uint256", internalType: "uint256" },
          { name: "amount", type: "uint256", internalType: "uint256" },
          {
            name: "amountToPay",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "debtor",
            type: "tuple",
            internalType: "struct InvoiceNFT.Company",
            components: [
              {
                name: "name",
                type: "address",
                internalType: "address",
              },
              {
                name: "creditScore",
                type: "uint8",
                internalType: "enum InvoiceNFT.CreditScore",
              },
            ],
          },
          {
            name: "creditor",
            type: "tuple",
            internalType: "struct InvoiceNFT.Company",
            components: [
              {
                name: "name",
                type: "address",
                internalType: "address",
              },
              {
                name: "creditScore",
                type: "uint8",
                internalType: "enum InvoiceNFT.CreditScore",
              },
            ],
          },
        ],
      },
    ],
    outputs: [{ name: "", type: "uint256", internalType: "uint256" }],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "getCreditorInvoices",
    inputs: [],
    outputs: [
      {
        name: "invoiceIds",
        type: "uint256[]",
        internalType: "uint256[]",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getDebtorInvoices",
    inputs: [],
    outputs: [
      {
        name: "invoiceIds",
        type: "uint256[]",
        internalType: "uint256[]",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getInvestorInvoices",
    inputs: [],
    outputs: [
      {
        name: "invoiceIds",
        type: "uint256[]",
        internalType: "uint256[]",
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "getInvoice",
    inputs: [{ name: "tokenId", type: "uint256", internalType: "uint256" }],
    outputs: [
      {
        name: "",
        type: "tuple",
        internalType: "struct InvoiceNFT.Invoice",
        components: [
          { name: "id", type: "string", internalType: "string" },
          { name: "activity", type: "string", internalType: "string" },
          { name: "country", type: "string", internalType: "string" },
          { name: "dueDate", type: "uint256", internalType: "uint256" },
          { name: "amount", type: "uint256", internalType: "uint256" },
          {
            name: "amountToPay",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "collateral",
            type: "uint256",
            internalType: "uint256",
          },
          {
            name: "debtor",
            type: "tuple",
            internalType: "struct InvoiceNFT.Company",
            components: [
              {
                name: "name",
                type: "address",
                internalType: "address",
              },
              {
                name: "creditScore",
                type: "uint8",
                internalType: "enum InvoiceNFT.CreditScore",
              },
            ],
          },
          {
            name: "creditor",
            type: "tuple",
            internalType: "struct InvoiceNFT.Company",
            components: [
              {
                name: "name",
                type: "address",
                internalType: "address",
              },
              {
                name: "creditScore",
                type: "uint8",
                internalType: "enum InvoiceNFT.CreditScore",
              },
            ],
          },
          {
            name: "investor",
            type: "tuple",
            internalType: "struct InvoiceNFT.Company",
            components: [
              {
                name: "name",
                type: "address",
                internalType: "address",
              },
              {
                name: "creditScore",
                type: "uint8",
                internalType: "enum InvoiceNFT.CreditScore",
              },
            ],
          },
          {
            name: "invoiceStatus",
            type: "uint8",
            internalType: "enum InvoiceNFT.InvoiceStatus",
          },
        ],
      },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "investInvoice",
    inputs: [
      { name: "tokenId", type: "uint256", internalType: "uint256" },
      {
        name: "investor",
        type: "tuple",
        internalType: "struct InvoiceNFT.Company",
        components: [
          { name: "name", type: "address", internalType: "address" },
          {
            name: "creditScore",
            type: "uint8",
            internalType: "enum InvoiceNFT.CreditScore",
          },
        ],
      },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "invoiceNFT",
    inputs: [],
    outputs: [
      { name: "", type: "address", internalType: "contract InvoiceNFT" },
    ],
    stateMutability: "view",
  },
  {
    type: "function",
    name: "payInvoice",
    inputs: [{ name: "tokenId", type: "uint256", internalType: "uint256" }],
    outputs: [],
    stateMutability: "nonpayable",
  },
  {
    type: "function",
    name: "primaToken",
    inputs: [],
    outputs: [
      { name: "", type: "address", internalType: "contract PrimaToken" },
    ],
    stateMutability: "view",
  },
  {
    type: "error",
    name: "Prima_InvalidCollateralAmount",
    inputs: [
      {
        name: "collateralAmount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "activeCollateral",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "totalCollateral",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  {
    type: "error",
    name: "Prima_InvalidDueDate",
    inputs: [{ name: "dueDate", type: "uint256", internalType: "uint256" }],
  },
  {
    type: "error",
    name: "Prima_InvalidInvoiceAmount",
    inputs: [
      { name: "amount", type: "uint256", internalType: "uint256" },
      { name: "amountToPay", type: "uint256", internalType: "uint256" },
    ],
  },
  {
    type: "error",
    name: "Prima_InvalidInvoiceAmountToPay",
    inputs: [
      { name: "amount", type: "uint256", internalType: "uint256" },
      {
        name: "minimumAmount",
        type: "uint256",
        internalType: "uint256",
      },
      {
        name: "maximumAmount",
        type: "uint256",
        internalType: "uint256",
      },
    ],
  },
  { type: "error", name: "Prima_InvalidInvoiceId", inputs: [] },
  {
    type: "error",
    name: "Prima_InvalidSender",
    inputs: [{ name: "sender", type: "address", internalType: "address" }],
  },
  { type: "error", name: "Prima_InvalidZeroAddress", inputs: [] },
];
