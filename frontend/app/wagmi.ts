import { getDefaultConfig } from "@rainbow-me/rainbowkit";
import { sepolia, foundry } from "wagmi/chains";
import { http } from "wagmi";

export const config = getDefaultConfig({
  appName: "Prima App",
  projectId: process.env.NEXT_PUBLIC_PROJECT_ID ?? "",
  chains: [foundry, sepolia],
  ssr: true,
  transports: {
    [sepolia.id]: http(process.env.NEXT_PUBLIC_RPC_URL),
    [foundry.id]: http(),
  },
});
