import { ExternalProvider } from "ethers";

declare global {
  interface Window {
    ethereum?: any; // Using 'any' for the provider to allow for common EIP-1193 patterns
  }
}
