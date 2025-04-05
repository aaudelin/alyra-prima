# Architecture du Projet Prima

## Diagramme UML des Smart Contracts

```mermaid
classDiagram
    class Prima {
        +InvoiceNFT invoiceNFT
        +Collateral collateral
        +PrimaToken primaToken
        -_debtorInvoices: mapping(address => uint256[])
        -_creditorInvoices: mapping(address => uint256[])
        -_investorInvoices: mapping(address => uint256[])
        -_activeCollateral: mapping(address => uint256)
        +addCollateral(collateralAmount: uint256)
        +computeAmounts(amount: uint256, debtorCreditScore: CreditScore): (uint256, uint256)
        +generateInvoice(invoiceParams: InvoiceParams): uint256
        +acceptInvoice(tokenId: uint256, collateralAmount: uint256)
        +investInvoice(tokenId: uint256, investor: Company)
        +payInvoice(tokenId: uint256)
        +getInvoice(tokenId: uint256): Invoice
        +getDebtorInvoices(): uint256[]
        +getCreditorInvoices(): uint256[]
        +getInvestorInvoices(): uint256[]
    }

    class InvoiceNFT {
        -_tokenIdCounter: uint256
        -_invoices: mapping(uint256 => Invoice)
        +createInvoice(to: address, invoiceParams: InvoiceParams): uint256
        +getInvoice(tokenId: uint256): Invoice
        +acceptInvoice(tokenId: uint256, collateral: uint256)
        +investInvoice(tokenId: uint256, investor: Company)
        +payInvoice(tokenId: uint256, success: bool)
        +tokenURI(tokenId: uint256): string
        +_baseURI(): string
        +_getSVG(): string
    }

    class Collateral {
        -collateral: mapping(address => uint256)
        +PrimaToken primaToken
        +deposit(to: address, collateralAmount: uint256)
        +withdraw(from: address, to: address, collateralAmount: uint256)
        +getCollateral(account: address): uint256
    }

    class PrimaToken {
        +mint(to: address, amount: uint256)
    }

    %% Structures et Enums
    class Company {
        +name: address
        +creditScore: CreditScore
    }

    class Invoice {
        +id: string
        +activity: string
        +country: string
        +dueDate: uint256
        +amount: uint256
        +amountToPay: uint256
        +collateral: uint256
        +debtor: Company
        +creditor: Company
        +investor: Company
        +invoiceStatus: InvoiceStatus
    }

    class InvoiceParams {
        +id: string
        +activity: string
        +country: string
        +dueDate: uint256
        +amount: uint256
        +amountToPay: uint256
        +debtor: Company
        +creditor: Company
    }

    class CreditScore {
        <<enumeration>>
        A
        B
        C
        D
        E
        F
    }

    class InvoiceStatus {
        <<enumeration>>
        NEW
        ACCEPTED
        IN_PROGRESS
        PAID
        OVERDUE
    }

    %% OpenZeppelin Contracts
    class ERC721 {
        <<interface>>
    }

    class ERC20 {
        <<interface>>
    }

    class Ownable {
        <<interface>>
    }

    class Math {
        <<utility>>
    }

    class Base64 {
        <<utility>>
    }

    class Strings {
        <<utility>>
    }

    %% Relations entre les contrats
    Prima --> InvoiceNFT : utilise
    Prima --> Collateral : utilise
    Prima --> PrimaToken : utilise
    Prima ..> Math : utilise
    Collateral --> PrimaToken : utilise

    %% Héritage et implémentation
    InvoiceNFT --|> ERC721
    InvoiceNFT --|> Ownable
    InvoiceNFT ..> Base64 : utilise
    InvoiceNFT ..> Strings : utilise
    PrimaToken --|> ERC20
    Collateral --|> Ownable

    %% Relations avec les structures
    Prima ..> Company : utilise
    Prima ..> InvoiceParams : utilise
    Prima ..> Invoice : utilise
    Prima ..> CreditScore : utilise
    InvoiceNFT ..> Invoice : utilise
    InvoiceNFT ..> InvoiceParams : utilise
    InvoiceNFT ..> Company : utilise
    InvoiceNFT ..> InvoiceStatus : utilise
    InvoiceNFT ..> CreditScore : utilise
```

## Description des Contrats

### Prima (Contrat Principal)
- Gère l'ensemble du système de financement de factures
- Coordonne les interactions entre les différents contrats
- Implémente la logique métier principale
- Stocke les mappings des factures par type d'utilisateur (débiteur, créancier, investisseur)
- Gère les garanties actives des débiteurs

### InvoiceNFT
- Gère les factures sous forme de NFTs (ERC721)
- Stocke les métadonnées des factures
- Gère les états des factures (NEW, ACCEPTED, IN_PROGRESS, PAID, OVERDUE)
- Implémente les fonctions de création, acceptation, investissement et paiement des factures
- Génère les métadonnées on-chain pour les NFTs

### Collateral
- Gère les garanties des débiteurs
- Permet le dépôt et le retrait des garanties
- Utilise le PrimaToken pour les transactions
- Vérifie les soldes suffisants avant les retraits

### PrimaToken
- Token ERC20 standard pour les transactions
- Utilisé pour les paiements et les garanties
- Permet le mint de nouveaux tokens

## Structures et Enums

### Company
- Structure représentant une entreprise
- Contient l'adresse et le score de crédit

### Invoice
- Structure complète d'une facture
- Contient toutes les informations nécessaires pour le financement

### InvoiceParams
- Structure pour la création d'une facture
- Contient les paramètres initiaux sans les informations d'investissement

### CreditScore
- Enumération des scores de crédit (A à F)
- Utilisé pour calculer les montants minimum et maximum des factures

### InvoiceStatus
- Enumération des états possibles d'une facture
- Trace le cycle de vie complet d'une facture

## Dépendances OpenZeppelin

### Contrats Standards
- ERC721 : Pour la gestion des NFTs (factures)
- ERC20 : Pour le token Prima
- Ownable : Pour la gestion des permissions

### Utilitaires
- Math : Pour les calculs de montants
- Base64 : Pour l'encodage des métadonnées
- Strings : Pour la manipulation des chaînes

## Flux d'Utilisation

1. **Création d'une Facture**
   - Le créancier crée une facture via Prima
   - La facture est mintée comme NFT
   - Le débiteur peut accepter la facture

2. **Gestion des Garanties**
   - Le débiteur dépose des garanties
   - Les garanties sont verrouillées pour la facture
   - Les garanties peuvent être utilisées en cas de défaut de paiement

3. **Investissement**
   - Un investisseur peut investir dans une facture
   - Le montant est transféré au créancier
   - L'investisseur devient propriétaire du NFT

4. **Paiement**
   - Le débiteur paie la facture
   - En cas de défaut, les garanties sont utilisées
   - Le NFT est marqué comme payé

## Sécurité

- Tous les contrats héritent des standards OpenZeppelin
- Les permissions sont gérées via Ownable
- Les calculs utilisent Math pour éviter les débordements
- Les transferts de tokens sont sécurisés via les standards ERC20/ERC721 