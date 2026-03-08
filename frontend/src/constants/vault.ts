export const VAULT_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
export const VAULT_ABI = [
  "function hasHighIncomeBadge() view returns (bool)",
  "function owner() view returns (address)",
  "function verifyIncome(uint[2] a, uint[2][2] b, uint[2] c, uint[2] input) external",
  "function execute(address dest, uint256 value, bytes calldata func) external"
];
