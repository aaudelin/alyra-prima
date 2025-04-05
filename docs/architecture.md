# Architecture du Projet Prima

## Diagramme UML des Smart Contracts

```mermaid
classDiagram
    class Prima {
        +InvoiceNFT invoiceNFT
        +Collateral collateral
        +PrimaToken primaToken
        +generateInvoice()
        +acceptInvoice()
        +investInvoice()
        +payInvoice()
        +addCollateral()
    }

    class InvoiceNFT {
        -_tokenIdCounter
        -_invoices
        +createInvoice()
        +acceptInvoice()
        +investInvoice()
        +payInvoice()
        +getInvoice()
    }

    class Collateral {
        -collateral
        +PrimaToken primaToken
        +deposit()
        +withdraw()
        +getCollateral()
    }

    class PrimaToken {
        +mint()
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
```

## Description des Contrats

### Prima (Contrat Principal)
- Gère l'ensemble du système de financement de factures
- Coordonne les interactions entre les différents contrats
- Implémente la logique métier principale

### InvoiceNFT
- Gère les factures sous forme de NFTs (ERC721)
- Stocke les métadonnées des factures
- Gère les états des factures (NEW, ACCEPTED, IN_PROGRESS, PAID, OVERDUE)

### Collateral
- Gère les garanties des débiteurs
- Permet le dépôt et le retrait des garanties
- Utilise le PrimaToken pour les transactions

### PrimaToken
- Token ERC20 standard pour les transactions
- Utilisé pour les paiements et les garanties

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