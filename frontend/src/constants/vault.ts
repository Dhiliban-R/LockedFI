export const VAULT_ADDRESS = "0x1fA02b2d6A771842690194Cf62D91bdd92BfE28d";
export const VAULT_ABI = [
  "function hasHighIncomeBadge() view returns (bool)",
  "function owner() view returns (address)",
  "function verifyIncome(uint[2] a, uint[2][2] b, uint[2] c, uint[2] input) external",
  "function execute(address dest, uint256 value, bytes calldata func) external"
];
