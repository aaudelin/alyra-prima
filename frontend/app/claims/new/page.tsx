"use client";

import ErrorComponent from "@/app/components/ErrorComponent";
import { PRIMA_ABI, PRIMA_ADDRESS } from "@/app/contracts";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import { Company, CreditScore } from "@/lib/types";
import { cn } from "@/lib/utils";
import { zodResolver } from "@hookform/resolvers/zod";
import { format } from "date-fns";
import { fr } from "date-fns/locale";
import { CalendarIcon } from "lucide-react";
import { useEffect, useState } from "react";
import { useForm } from "react-hook-form";
import { formatEther, parseEther } from "viem";
import {
  type BaseError,
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import { z } from "zod";

const FormSchema = z.object({
  id: z.string().min(4, {
    message: "ID doit faire au moins 4 caractères.",
  }),
  activity: z.string().min(10, {
    message: "Activité doit faire au moins 10 caractères.",
  }),
  country: z.string().min(2, {
    message: "Pays doit faire au moins 2 caractères.",
  }),
  dueDate: z.date().min(new Date(), {
    message: "Date d'échéance doit être dans le futur.",
  }),
  amount: z.number().min(1, {
    message: "Montant doit dépasser 1.",
  }),
  amountToPay: z.number().min(1, {
    message: "Montant à payer doit dépasser 1.",
  }),
  debtorName: z.string().min(32, {
    message: "Nom du débiteur doit être l'adresse ethereum sur 32 caractères.",
  }),
  debtorScore: z.number().min(0).max(5),
});

export default function NewClaim() {
  const { address } = useAccount();
  const [amountTotal, setAmountTotal] = useState<bigint>(parseEther("1000"));
  const [creditor, setCreditor] = useState<Company>({
    name: address as `0x${string}`,
    creditScore: Math.floor(Math.random() * 5),
  });
  const [debtor] = useState<Company>({
    name: "0x1234567890123456789012345678901234567890" as `0x${string}`,
    creditScore: Math.floor(Math.random() * 5),
  });

  const { data: hash, writeContract, error: writeError } = useWriteContract();
  const {
    isLoading: isConfirming,
    isSuccess: isConfirmed,
    isError: isError
  } = useWaitForTransactionReceipt({
    hash,
  });

  useEffect(() => {
    setCreditor({
      name: address as `0x${string}`,
      creditScore: Math.floor(Math.random() * 5),
    });
  }, [address]);

  const form = useForm<z.infer<typeof FormSchema>>({
    resolver: zodResolver(FormSchema),
    defaultValues: {
      id: "",
      activity: "",
      country: "",
      dueDate: new Date(),
      amount: undefined,
      amountToPay: undefined,
      debtorName: "",
      debtorScore: debtor.creditScore,
    },
  });

  const { data: minMaxAmounts } = useReadContract({
    address: PRIMA_ADDRESS,
    abi: PRIMA_ABI,
    functionName: "computeAmounts",
    args: [amountTotal, debtor.creditScore],
    account: address,
  }) as { data: [bigint, bigint] };

  function onSubmit(values: z.infer<typeof FormSchema>) {
    const newDebtor = {
      name: values.debtorName,
      creditScore: debtor.creditScore,
    };
    const invoiceParams = {
      id: values.id,
      activity: values.activity,
      country: values.country,
      dueDate: values.dueDate.getTime(),
      amount: parseEther(values.amount.toString()),
      amountToPay: parseEther(values.amountToPay.toString()),
      debtor: newDebtor,
      creditor,
    };
    try {
      writeContract({
        address: PRIMA_ADDRESS,
        abi: PRIMA_ABI,
        functionName: "generateInvoice",
        args: [invoiceParams],
        account: address,
      });
    } catch (error) {
      console.log(error);
    }
  }

  return (
    <div>
      <h1 className="text-4xl font-bold">Nouvelle créance</h1>
      <Form {...form}>
        <form
          onSubmit={form.handleSubmit(onSubmit)}
          className="mt-8 space-y-4 max-w-2xl"
        >
          <h3 className="text-lg font-medium">Informations de la créance</h3>
          <FormField
            control={form.control}
            name="id"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Identifiant de la créance</FormLabel>
                <FormControl>
                  <Input type="text" placeholder="INV-001" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="activity"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Activité</FormLabel>
                <FormControl>
                  <Input
                    type="text"
                    placeholder="Vente de produits"
                    {...field}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="country"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Pays</FormLabel>
                <FormControl>
                  <Input type="text" placeholder="France" {...field} />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />
          <FormField
            control={form.control}
            name="dueDate"
            render={({ field }) => (
              <FormItem className="flex flex-col">
                <FormLabel>Date d&apos;échéance</FormLabel>
                <Popover>
                  <PopoverTrigger asChild>
                    <FormControl>
                      <Button
                        variant={"outline"}
                        className={cn(
                          "w-[240px] pl-3 text-left font-normal",
                          !field.value && "text-muted-foreground"
                        )}
                      >
                        {field.value ? (
                          format(field.value, "dd/MM/yyyy")
                        ) : (
                          <span>Choisir une date</span>
                        )}
                        <CalendarIcon className="ml-auto h-4 w-4 opacity-50" />
                      </Button>
                    </FormControl>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0" align="start">
                    <Calendar
                      mode="single"
                      locale={fr}
                      selected={field.value}
                      onSelect={field.onChange}
                      disabled={(date) => date < new Date()}
                      initialFocus
                    />
                  </PopoverContent>
                </Popover>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="amount"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Montant de la créance</FormLabel>
                <FormControl>
                  <Input
                    {...field}
                    placeholder="1000"
                    type="number"
                    onChange={(e) =>
                      field.onChange(
                        e.target.value ? Number(e.target.value) : null
                      )
                    }
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <h3 className="text-lg font-medium">Débiteur</h3>
          <FormField
            control={form.control}
            name="debtorName"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Adresse Ethereum du débiteur</FormLabel>
                <FormControl>
                  <Input
                    placeholder="0x1234567890123456789012345678901234567890"
                    type="text"
                    {...field}
                  />
                </FormControl>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="debtorScore"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Note de crédit</FormLabel>
                <FormControl>
                  <Input
                    disabled
                    type="text"
                    {...field}
                    value={CreditScore[field.value]}
                  />
                </FormControl>
                <FormDescription>
                  Cette note de crédit est générée aléatoirement pour le POC.
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />

          <FormField
            control={form.control}
            name="amountToPay"
            render={({ field }) => (
              <FormItem>
                <FormLabel>Montant à payer</FormLabel>
                <FormControl>
                  <Input
                    {...field}
                    type="number"
                    placeholder="990"
                    onChange={(e) =>
                      field.onChange(
                        e.target.value ? Number(e.target.value) : null
                      )
                    }
                  />
                </FormControl>
                <FormDescription>
                  {`Ce montant doit être compris entre ${formatEther(minMaxAmounts?.[0] ?? BigInt(0))} et ${formatEther(minMaxAmounts?.[1] ?? BigInt(0))}`}
                  <Button
                    type="button"
                    className="ml-4"
                    size={"sm"}
                    variant={"outline"}
                    onClick={() =>
                      setAmountTotal(parseEther(form.getValues("amount")?.toString() ?? "1000"))
                    }
                  >
                    Vérifier le montant
                  </Button>
                </FormDescription>
                <FormMessage />
              </FormItem>
            )}
          />
          {isConfirming && <div>Envoi de la transaction...</div>}
          {isConfirmed && <div className="text-green-500">Votre créance a bien été générée.</div>}
          {isError && <div className="text-red-500">Erreur lors de la génération de la créance.</div>}
          {writeError && <ErrorComponent error={writeError as BaseError} />}
          <Button type="submit">Créer la créance</Button>
        </form>
      </Form>
    </div>
  );
}
