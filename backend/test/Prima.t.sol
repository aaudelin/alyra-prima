// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from "forge-std/Test.sol";
import {Prima} from "../src/Prima.sol";
import "../script/Prima.s.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {Collateral} from "../src/Collateral.sol";
import {PrimaToken} from "../src/PrimaToken.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract PrimaDeploymentTest is Test {
    Prima prima;
    PrimaScript primaScript;
    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");
    address investor = makeAddr("investor");

    address private owner = address(this);

    function test_Deployment_Script() public {
        PrimaToken primaToken = new PrimaToken();
        primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();

        assertNotEq(address(prima), address(0));
        assertNotEq(address(prima.invoiceNFT()), address(0));
        assertNotEq(address(prima.collateral()), address(0));
        assertNotEq(address(prima.primaToken()), address(0));
        assertEq(prima.invoiceNFT().owner(), address(prima));
        assertEq(prima.collateral().owner(), address(prima));
    }
}

contract PrimaCollateralTest is Test {
    Prima prima;
    Collateral collateral;
    PrimaToken primaToken;
    uint256 primaTokenDecimals;

    address debtor = makeAddr("debtor");

    function setUp() public {
        // Deploy contracts
        primaToken = new PrimaToken();
        PrimaScript primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
        collateral = prima.collateral();
        primaTokenDecimals = primaToken.decimals();
    }

    function test_AddCollateral_Success() public {
        primaToken.mint(debtor, 1000000 * 10 ** primaTokenDecimals);
        uint256 collateralAmount = 100 * 10 ** primaTokenDecimals;
        vm.startPrank(debtor);
        primaToken.approve(address(prima), collateralAmount);
        prima.addCollateral(collateralAmount);
        vm.stopPrank();

        vm.startPrank(address(prima));
        assertEq(primaToken.balanceOf(address(collateral)), collateralAmount);
        assertEq(collateral.getCollateral(debtor), collateralAmount);
        assertEq(primaToken.allowance(address(collateral), address(prima)), collateralAmount);
        vm.stopPrank();
    }

    function test_AddCollateral_SuccessTwoDeposits() public {
        primaToken.mint(debtor, 1000000 * 10 ** primaTokenDecimals);
        uint256 collateralAmount = 100 * 10 ** primaTokenDecimals;
        vm.startPrank(debtor);
        primaToken.approve(address(prima), collateralAmount);
        prima.addCollateral(collateralAmount);
        primaToken.approve(address(prima), collateralAmount);
        prima.addCollateral(collateralAmount);
        vm.stopPrank();

        vm.startPrank(address(prima));
        assertEq(primaToken.balanceOf(address(collateral)), 2 * collateralAmount);
        assertEq(collateral.getCollateral(debtor), 2 * collateralAmount);
        assertEq(primaToken.allowance(address(collateral), address(prima)), 2 * collateralAmount);
        vm.stopPrank();
    }

    function test_AddCollateral_ZeroAllowance() public {
        vm.startPrank(debtor);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, address(prima), 0, 100 * 10 ** primaTokenDecimals
            )
        );
        prima.addCollateral(100 * 10 ** primaTokenDecimals);
        vm.stopPrank();
    }

    function test_AddCollateral_InsufficientAllowance() public {
        vm.startPrank(debtor);
        primaToken.approve(address(prima), 10 * 10 ** primaTokenDecimals);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                address(prima),
                10 * 10 ** primaTokenDecimals,
                100 * 10 ** primaTokenDecimals
            )
        );
        prima.addCollateral(100 * 10 ** primaTokenDecimals);
        vm.stopPrank();
    }

    function test_AddCollateral_Failure_TransferFailed() public {
        primaToken.mint(debtor, 1000000 * 10 ** primaTokenDecimals);
        uint256 collateralAmount = 100 * 10 ** primaTokenDecimals;
        vm.startPrank(debtor);
        primaToken.approve(address(prima), collateralAmount);
        vm.mockCall(address(primaToken), abi.encodeWithSelector(ERC20.transferFrom.selector), abi.encode(false));
        vm.expectRevert();
        prima.addCollateral(collateralAmount);
        vm.stopPrank();
    }
}

contract PrimaAmountsTest is Test {
    Prima prima;

    function setUp() public {
        // Deploy contracts
        PrimaToken primaToken = new PrimaToken();
        PrimaScript primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
    }

    function test_ComputeAmounts_A() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.A);
        assertEq(minimumAmount, 95);
        assertEq(maximumAmount, 100);
    }

    function test_ComputeAmounts_B() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.B);
        assertEq(minimumAmount, 90);
        assertEq(maximumAmount, 95);
    }

    function test_ComputeAmounts_C() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.C);
        assertEq(minimumAmount, 85);
        assertEq(maximumAmount, 90);
    }

    function test_ComputeAmounts_D() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.D);
        assertEq(minimumAmount, 80);
        assertEq(maximumAmount, 85);
    }

    function test_ComputeAmounts_E() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.E);
        assertEq(minimumAmount, 75);
        assertEq(maximumAmount, 80);
    }

    function test_ComputeAmounts_F() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(100, InvoiceNFT.CreditScore.F);
        assertEq(minimumAmount, 70);
        assertEq(maximumAmount, 75);
    }

    function test_ComputeAmounts_Zero() public view {
        (uint256 minimumAmount, uint256 maximumAmount) = prima.computeAmounts(0, InvoiceNFT.CreditScore.A);
        assertEq(minimumAmount, 0);
        assertEq(maximumAmount, 0);
    }
}

contract PrimaGenerateInvoiceTest is Test {
    Prima prima;
    PrimaScript primaScript;
    InvoiceNFT invoiceNFT;
    PrimaToken primaToken;
    address creditor = makeAddr("creditor");
    address debtor = makeAddr("debtor");

    function setUp() public {
        // Deploy contracts
        primaToken = new PrimaToken();
        primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
        invoiceNFT = prima.invoiceNFT();
    }

    function testFuzz_GenerateInvoice_Success_SameAmount(uint256 amount) public {
        vm.assume(amount > 0);
        vm.startPrank(creditor);
        InvoiceNFT.InvoiceParams memory invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: amount,
            amountToPay: amount,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        uint256 tokenId = prima.generateInvoice(invoiceParams);
        vm.stopPrank();

        vm.prank(address(prima));
        InvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(tokenId);

        assertEq(tokenId, 1);
        assertEq(invoice.id, invoiceParams.id);
        assertEq(invoice.activity, invoiceParams.activity);
        assertEq(invoice.country, invoiceParams.country);
        assertEq(invoice.dueDate, invoiceParams.dueDate);
        assertEq(invoice.amount, invoiceParams.amount);
        assertEq(invoice.amountToPay, invoiceParams.amountToPay);
        assertEq(invoice.debtor.name, invoiceParams.debtor.name);
        assertEq(invoice.creditor.name, invoiceParams.creditor.name);
        assertEq(uint256(invoice.invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.NEW));
        assertEq(invoice.collateral, 0);
        assertEq(invoice.investor.name, address(0));
    }

    function testFuzz_GenerateInvoice_Success_DebtorCreditScore(uint256 debtorCreditScore) public {
        vm.assume(debtorCreditScore <= 5);
        uint256 amount = 100;
        (uint256 amountToPay,) = prima.computeAmounts(amount, InvoiceNFT.CreditScore(debtorCreditScore));
        vm.startPrank(creditor);
        InvoiceNFT.InvoiceParams memory invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: amount,
            amountToPay: amountToPay,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore(debtorCreditScore)}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        uint256 tokenId = prima.generateInvoice(invoiceParams);
        vm.stopPrank();

        vm.prank(address(prima));
        InvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(tokenId);

        assertEq(tokenId, 1);
        assertEq(invoice.amount, invoiceParams.amount);
        assertEq(invoice.amountToPay, invoiceParams.amountToPay);
    }

    function test_GenerateInvoice_Success_DifferentAmount() public {
        vm.startPrank(creditor);
        InvoiceNFT.InvoiceParams memory invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        uint256 tokenId = prima.generateInvoice(invoiceParams);
        vm.stopPrank();

        vm.prank(address(prima));
        InvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(tokenId);

        assertEq(tokenId, 1);
        assertEq(invoice.amount, invoiceParams.amount);
        assertEq(invoice.amountToPay, invoiceParams.amountToPay);
    }

    function test_GenerateInvoice_SameInvoices() public {
        vm.startPrank(creditor);
        InvoiceNFT.InvoiceParams memory invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        uint256 tokenId = prima.generateInvoice(invoiceParams);
        assertEq(tokenId, 1);
        tokenId = prima.generateInvoice(invoiceParams);
        assertEq(tokenId, 2);
        tokenId = prima.generateInvoice(invoiceParams);
        assertEq(tokenId, 3);
        tokenId = prima.generateInvoice(invoiceParams);
        assertEq(tokenId, 4);
        vm.stopPrank();
    }

    function test_GenerateInvoice_DifferentInvoices() public {
        vm.startPrank(creditor);
        InvoiceNFT.InvoiceParams memory invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        InvoiceNFT.InvoiceParams memory invoiceParams2 = InvoiceNFT.InvoiceParams({
            id: "2",
            activity: "Import of goods",
            country: "France",
            dueDate: block.timestamp + 3000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        InvoiceNFT.InvoiceParams memory invoiceParams3 = InvoiceNFT.InvoiceParams({
            id: "3",
            activity: "Computer Electronics",
            country: "Germany",
            dueDate: block.timestamp + 2000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        InvoiceNFT.InvoiceParams memory invoiceParams4 = InvoiceNFT.InvoiceParams({
            id: "4",
            activity: "Baby care",
            country: "Spain",
            dueDate: block.timestamp + 4000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        uint256 tokenId = prima.generateInvoice(invoiceParams);
        assertEq(tokenId, 1);
        tokenId = prima.generateInvoice(invoiceParams2);
        assertEq(tokenId, 2);
        tokenId = prima.generateInvoice(invoiceParams3);
        assertEq(tokenId, 3);
        tokenId = prima.generateInvoice(invoiceParams4);
        assertEq(tokenId, 4);
        vm.stopPrank();
    }

    function test_GenerateInvoice_Revert_NoId() public {
        vm.startPrank(creditor);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidInvoiceId.selector));
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();
    }

    function testFuzz_GenerateInvoice_Revert_InvalidDueDate(uint256 dueDateDelay) public {
        vm.assume(dueDateDelay < block.timestamp);
        uint256 dueDate = block.timestamp - dueDateDelay;
        vm.startPrank(creditor);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidDueDate.selector, dueDate));
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: dueDate,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();
    }

    function test_GenerateInvoice_Revert_InvalidAmount() public {
        vm.startPrank(creditor);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidInvoiceAmount.selector, 90, 98));
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 90,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();
    }

    function test_GenerateInvoice_Revert_InvalidZeroAddress_Debtor() public {
        vm.startPrank(creditor);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidZeroAddress.selector));
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: address(0), creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();
    }

    function test_GenerateInvoice_Revert_InvalidZeroAddress_Creditor() public {
        vm.startPrank(creditor);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidSender.selector, creditor));
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: address(0), creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();
    }

    function test_GenerateInvoice_Revert_InvalidAmountToPay() public {
        vm.startPrank(creditor);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidInvoiceAmountToPay.selector, 76, 95, 100));
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 76,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();
    }

    function test_GenerateInvoice_ExpectEmit_StatusChanged() public {
        vm.startPrank(creditor);
        vm.expectEmit(address(invoiceNFT));
        emit InvoiceNFT.InvoiceNFT_StatusChanged(1, InvoiceNFT.InvoiceStatus.NEW);
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();
    }
}

contract PrimaAcceptInvoiceTest is Test {
    Prima prima;
    PrimaScript primaScript;
    InvoiceNFT invoiceNFT;
    Collateral collateral;
    PrimaToken primaToken;
    InvoiceNFT.Invoice invoice;
    InvoiceNFT.InvoiceParams invoiceParams;

    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");

    function setUp() public {
        // Deploy contracts
        primaToken = new PrimaToken();
        primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
        invoiceNFT = prima.invoiceNFT();
        collateral = prima.collateral();

        vm.startPrank(creditor);
        invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        prima.generateInvoice(invoiceParams);
        vm.stopPrank();

        vm.startPrank(address(prima));
        invoice = invoiceNFT.getInvoice(1);
        vm.stopPrank();
    }

    function test_AcceptInvoice_Success() public {
        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 100);
        prima.addCollateral(100);
        prima.acceptInvoice(1, 100);
        vm.stopPrank();

        vm.startPrank(address(prima));
        InvoiceNFT.Invoice memory getInvoice = invoiceNFT.getInvoice(1);
        assertEq(getInvoice.collateral, 100);
        assertEq(uint256(getInvoice.invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.ACCEPTED));
        vm.stopPrank();
    }

    function test_AcceptInvoice_Success_MultipleCollaterals() public {
        vm.prank(creditor);
        prima.generateInvoice(invoiceParams);

        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 100);
        prima.addCollateral(100);
        prima.acceptInvoice(1, 50);
        prima.acceptInvoice(2, 50);
        vm.stopPrank();

        vm.startPrank(address(prima));
        InvoiceNFT.Invoice memory getInvoice1 = invoiceNFT.getInvoice(1);
        InvoiceNFT.Invoice memory getInvoice2 = invoiceNFT.getInvoice(2);
        assertEq(getInvoice1.collateral, 50);
        assertEq(uint256(getInvoice1.invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.ACCEPTED));
        assertEq(getInvoice2.collateral, 50);
        assertEq(uint256(getInvoice2.invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.ACCEPTED));
        vm.stopPrank();
    }

    function test_AcceptInvoice_Revert_InvalidDebtor() public {
        address debtor2 = makeAddr("debtor2");
        vm.startPrank(debtor2);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidSender.selector, debtor2));
        prima.acceptInvoice(1, 100);
        vm.stopPrank();
    }

    function test_AcceptInvoice_Revert_InvalidCollateralAmount() public {
        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 20);
        prima.addCollateral(20);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidCollateralAmount.selector, 100, 0, 20));
        prima.acceptInvoice(1, 100);
        vm.stopPrank();
    }

    function test_AcceptInvoice_Revert_InvalidSecondCollateralAmount() public {
        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 100);
        prima.addCollateral(100);
        prima.acceptInvoice(1, 80);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidCollateralAmount.selector, 40, 80, 100));
        prima.acceptInvoice(1, 40);
        vm.stopPrank();
    }

    function test_AcceptInvoice_Revert_SameInvoiceId() public {
        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 100);
        prima.addCollateral(100);
        prima.acceptInvoice(1, 10);

        vm.expectRevert(
            abi.encodeWithSelector(
                InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, 1, InvoiceNFT.InvoiceStatus.ACCEPTED
            )
        );
        prima.acceptInvoice(1, 10);
        vm.stopPrank();
    }
}

contract PrimaInvestInvoiceTest is Test {
    Prima prima;
    PrimaScript primaScript;
    InvoiceNFT invoiceNFT;
    PrimaToken primaToken;
    InvoiceNFT.Invoice invoice;
    InvoiceNFT.InvoiceParams invoiceParams;
    InvoiceNFT.Company investorCompany;

    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");
    address investor = makeAddr("investor");

    function setUp() public {
        // Deploy contracts
        primaToken = new PrimaToken();
        primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
        invoiceNFT = prima.invoiceNFT();
        investorCompany = InvoiceNFT.Company({name: investor, creditScore: InvoiceNFT.CreditScore.A});

        vm.startPrank(creditor);
        invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        prima.generateInvoice(invoiceParams);
        vm.stopPrank();

        vm.startPrank(address(prima));
        invoice = invoiceNFT.getInvoice(1);
        vm.stopPrank();
    }

    function test_InvestInvoice_Success() public {
        vm.startPrank(debtor);
        prima.acceptInvoice(1, 0);
        vm.stopPrank();

        vm.startPrank(investor);
        primaToken.mint(investor, 1000000);
        primaToken.approve(address(prima), invoice.amountToPay);
        prima.investInvoice(1, investorCompany);
        vm.stopPrank();

        vm.startPrank(address(prima));
        InvoiceNFT.Invoice memory getInvoice = invoiceNFT.getInvoice(1);
        assertEq(getInvoice.investor.name, investor);
        assertEq(uint256(getInvoice.invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.IN_PROGRESS));
        vm.stopPrank();

        assertEq(primaToken.balanceOf(investor), 1000000 - invoice.amountToPay);
        assertEq(primaToken.balanceOf(creditor), invoice.amountToPay);
    }

    function test_Success_Emit() public {
        vm.startPrank(debtor);
        prima.acceptInvoice(1, 0);
        vm.stopPrank();

        vm.startPrank(investor);
        primaToken.mint(investor, 1000000);
        primaToken.approve(address(prima), invoice.amountToPay);
        vm.expectEmit(address(invoiceNFT));
        emit InvoiceNFT.InvoiceNFT_StatusChanged(1, InvoiceNFT.InvoiceStatus.IN_PROGRESS);
        prima.investInvoice(1, investorCompany);
        vm.stopPrank();
    }

    function test_InvestInvoice_Revert_AlreadyInvested() public {
        InvoiceNFT.Company memory investorCompany2 =
            InvoiceNFT.Company({name: makeAddr("investor2"), creditScore: InvoiceNFT.CreditScore.A});
        vm.startPrank(debtor);
        prima.acceptInvoice(1, 0);
        vm.stopPrank();

        vm.startPrank(investorCompany.name);
        primaToken.mint(investor, 1000000);
        primaToken.approve(address(prima), invoice.amountToPay);
        prima.investInvoice(1, investorCompany);
        vm.stopPrank();

        vm.startPrank(investorCompany2.name);
        primaToken.mint(investorCompany2.name, 1000000);
        primaToken.approve(address(prima), invoice.amountToPay);
        vm.expectRevert(
            abi.encodeWithSelector(
                InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, 1, InvoiceNFT.InvoiceStatus.IN_PROGRESS
            )
        );
        prima.investInvoice(1, investorCompany2);
        vm.stopPrank();
    }

    function test_InvestInvoice_Revert_InvalidSender() public {
        address invalidSender = makeAddr("invalidSender");
        vm.startPrank(invalidSender);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidSender.selector, invalidSender));
        prima.investInvoice(1, investorCompany);
        vm.stopPrank();
    }

    function test_InvestInvoice_Failure_TransferFailed() public {
        vm.startPrank(debtor);
        prima.acceptInvoice(1, 0);
        vm.stopPrank();

        vm.startPrank(investor);
        primaToken.mint(investor, 1000000);
        primaToken.approve(address(prima), invoice.amountToPay);
        vm.mockCall(address(primaToken), abi.encodeWithSelector(ERC20.transferFrom.selector), abi.encode(false));
        vm.expectRevert();
        prima.investInvoice(1, investorCompany);
        vm.stopPrank();
    }
}

contract PrimaPayInvoiceTest is Test {
    Prima prima;
    PrimaScript primaScript;
    InvoiceNFT invoiceNFT;
    PrimaToken primaToken;
    Collateral collateral;
    InvoiceNFT.Invoice invoice;
    InvoiceNFT.InvoiceParams invoiceParams;

    address debtor = makeAddr("debtor");
    address creditor = makeAddr("creditor");
    address investor = makeAddr("investor");

    function setUp() public {
        // Deploy contracts
        primaToken = new PrimaToken();
        primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
        invoiceNFT = prima.invoiceNFT();
        collateral = prima.collateral();

        vm.startPrank(creditor);
        invoiceParams = InvoiceNFT.InvoiceParams({
            id: "1",
            activity: "Export of goods",
            country: "Italy",
            dueDate: block.timestamp + 1000,
            amount: 100,
            amountToPay: 98,
            debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
            creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
        });
        prima.generateInvoice(invoiceParams);
        vm.stopPrank();

        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 20);
        prima.addCollateral(20);
        prima.acceptInvoice(1, 20);
        vm.stopPrank();

        vm.startPrank(investor);
        primaToken.mint(investor, 1000000);
        primaToken.approve(address(prima), 98);
        prima.investInvoice(1, InvoiceNFT.Company({name: investor, creditScore: InvoiceNFT.CreditScore.A}));
        vm.stopPrank();

        vm.startPrank(address(prima));
        invoice = invoiceNFT.getInvoice(1);
        vm.stopPrank();
    }

    function test_PayInvoice_Success() public {
        uint256 initialInvestorBalance = primaToken.balanceOf(investor);
        uint256 initialDebtorBalance = primaToken.balanceOf(debtor);

        vm.startPrank(debtor);
        primaToken.approve(address(prima), invoice.amount);
        prima.payInvoice(1);
        vm.stopPrank();

        vm.startPrank(address(prima));
        InvoiceNFT.Invoice memory getInvoice = invoiceNFT.getInvoice(1);
        assertEq(uint256(getInvoice.invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.PAID));
        assertEq(primaToken.balanceOf(debtor), initialDebtorBalance - invoice.amount);
        assertEq(primaToken.balanceOf(investor), initialInvestorBalance + invoice.amount);
        vm.stopPrank();
    }

    function test_PayInvoice_Revert_WrongStatus() public {
        vm.startPrank(debtor);
        primaToken.approve(address(prima), invoice.amount);
        prima.payInvoice(1);
        vm.stopPrank();

        vm.startPrank(debtor);
        primaToken.approve(address(prima), invoice.amount);
        vm.expectRevert(
            abi.encodeWithSelector(InvoiceNFT.InvoiceNFT_WrongInvoiceStatus.selector, 1, InvoiceNFT.InvoiceStatus.PAID)
        );
        prima.payInvoice(1);
        vm.stopPrank();
    }

    function test_PayInvoice_Revert_WrongDebtor() public {
        vm.startPrank(investor);
        vm.expectRevert(abi.encodeWithSelector(Prima.Prima_InvalidSender.selector, investor));
        prima.payInvoice(1);
        vm.stopPrank();
    }

    function test_Success_Emit() public {
        vm.startPrank(debtor);
        primaToken.approve(address(prima), invoice.amount);
        vm.expectEmit();
        emit InvoiceNFT.InvoiceNFT_StatusChanged(1, InvoiceNFT.InvoiceStatus.PAID);
        prima.payInvoice(1);
        vm.stopPrank();
    }

    function test_PayInvoice_Success_UseCollateral() public {
        uint256 initialDebtorBalance = primaToken.balanceOf(debtor);
        uint256 initialInvestorBalance = primaToken.balanceOf(investor);
        uint256 initialCollateralBalance = primaToken.balanceOf(address(collateral));
        vm.startPrank(debtor);
        primaToken.transfer(address(prima), initialDebtorBalance);
        prima.payInvoice(1);
        vm.stopPrank();

        vm.startPrank(address(prima));
        InvoiceNFT.Invoice memory getInvoice = invoiceNFT.getInvoice(1);
        assertEq(uint256(getInvoice.invoiceStatus), uint256(InvoiceNFT.InvoiceStatus.OVERDUE));
        assertEq(primaToken.balanceOf(investor), initialInvestorBalance + invoice.collateral);
        assertEq(primaToken.balanceOf(address(collateral)), initialCollateralBalance - invoice.collateral);
        vm.stopPrank();

        vm.startPrank(address(prima));
        assertEq(collateral.getCollateral(debtor), 0);
        vm.stopPrank();
    }

    function test_PayInvoice_Failure_TransferFailed() public {
        vm.startPrank(debtor);
        primaToken.approve(address(prima), invoice.amount);
        vm.mockCall(address(primaToken), abi.encodeWithSelector(ERC20.transferFrom.selector), abi.encode(false));
        vm.expectRevert();
        prima.payInvoice(1);
        vm.stopPrank();
    }
}

contract PrimaGetInvoicesTest is Test {
    Prima prima;
    PrimaScript primaScript;
    PrimaToken primaToken;
    address creditor = makeAddr("creditor");
    address debtor = makeAddr("debtor");
    address investor = makeAddr("investor");

    function setUp() public {
        // Deploy contracts
        primaToken = new PrimaToken();
        primaScript = new PrimaScript();
        primaScript.run(address(primaToken));
        prima = primaScript.prima();
    }

    function test_GetInvoice_Success() public {
        vm.startPrank(creditor);
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();

        vm.startPrank(creditor);
        InvoiceNFT.Invoice memory invoice = prima.getInvoice(1);
        assertEq(invoice.id, "1");
        vm.stopPrank();
    }

    function test_GetInvoice_Success_Debtor() public {
        vm.startPrank(creditor);
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();

        vm.startPrank(debtor);
        InvoiceNFT.Invoice memory invoice = prima.getInvoice(1);
        assertEq(invoice.id, "1");
        vm.stopPrank();
    }

    function test_GetInvoice_Success_Investor() public {
        vm.startPrank(creditor);
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        vm.stopPrank();

        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 30);
        prima.addCollateral(30);
        prima.acceptInvoice(1, 30);
        vm.stopPrank();

        vm.startPrank(investor);
        primaToken.mint(investor, 1000000);
        primaToken.approve(address(prima), 98);
        prima.investInvoice(1, InvoiceNFT.Company({name: investor, creditScore: InvoiceNFT.CreditScore.A}));
        InvoiceNFT.Invoice memory invoice = prima.getInvoice(1);
        assertEq(invoice.id, "1");
        vm.stopPrank();
    }

    function test_GetInvoices_Success() public {
        vm.startPrank(creditor);
        prima.generateInvoice(
            InvoiceNFT.InvoiceParams({
                id: "1",
                activity: "Export of goods",
                country: "Italy",
                dueDate: block.timestamp + 1000,
                amount: 100,
                amountToPay: 98,
                debtor: InvoiceNFT.Company({name: debtor, creditScore: InvoiceNFT.CreditScore.A}),
                creditor: InvoiceNFT.Company({name: creditor, creditScore: InvoiceNFT.CreditScore.A})
            })
        );
        assertEq(prima.getCreditorInvoices().length, 1);
        assertEq(prima.getCreditorInvoices()[0], 1);
        vm.stopPrank();

        vm.startPrank(debtor);
        primaToken.mint(debtor, 1000000);
        primaToken.approve(address(prima), 30);
        prima.addCollateral(30);
        prima.acceptInvoice(1, 30);
        assertEq(prima.getDebtorInvoices().length, 1);
        assertEq(prima.getDebtorInvoices()[0], 1);
        vm.stopPrank();

        vm.startPrank(investor);
        primaToken.mint(investor, 1000000);
        primaToken.approve(address(prima), 98);
        prima.investInvoice(1, InvoiceNFT.Company({name: investor, creditScore: InvoiceNFT.CreditScore.A}));
        assertEq(prima.getInvestorInvoices().length, 1);
        assertEq(prima.getInvestorInvoices()[0], 1);
        vm.stopPrank();
    }

    function test_GetDebtorInvoices_Empty() public {
        vm.startPrank(debtor);
        uint256[] memory invoiceIds = prima.getDebtorInvoices();
        assertEq(invoiceIds.length, 0);
        vm.stopPrank();
    }

    function test_GetCreditorInvoices_Empty() public {
        vm.startPrank(creditor);
        uint256[] memory invoiceIds = prima.getCreditorInvoices();
        assertEq(invoiceIds.length, 0);
        vm.stopPrank();
    }

    function test_GetInvestorInvoices_Empty() public {
        vm.startPrank(investor);
        uint256[] memory invoiceIds = prima.getInvestorInvoices();
        assertEq(invoiceIds.length, 0);
        vm.stopPrank();
    }
}
