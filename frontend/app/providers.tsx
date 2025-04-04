"use client";

import type React from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { WagmiProvider } from "wagmi";
import {
  AvatarComponent,
  lightTheme,
  RainbowKitProvider,
} from "@rainbow-me/rainbowkit";

import { config } from "./wagmi";

const CustomAvatar: AvatarComponent = ({ size }) => {
  const color = "hsl(var(--primary))";
  return (
    <div
      style={{
        backgroundColor: color,
        borderRadius: 999,
        height: size,
        width: size,
      }}
    >
      
    </div>
  );
};

const queryClient = new QueryClient();

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider
          avatar={CustomAvatar}
          theme={lightTheme({
            accentColor: "hsl(var(--primary))",
            accentColorForeground: "hsl(var(--primary-foreground))",
          })}
        >
          {children}
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
