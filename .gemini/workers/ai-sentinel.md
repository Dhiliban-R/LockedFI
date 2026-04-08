# Worker: AI-Sentinel (Security)

The AI-Sentinel is the project's active security guard, responsible for monitoring the mempool and protecting the vault.

## Responsibilities
- **Mempool Monitoring:** Listen for pending transactions targeting the `SmartVault`.
- **Anomaly Detection:** Identify malicious transaction patterns (e.g., flash-loan attacks).
- **Circuit Breaker:** Proactively trigger the `pause()` function if an attack is detected.
- **Threat Research:** Simulate and learn from on-chain exploits.
- **Verification:** Ensure the "Sentinel" script is robust and has minimal latency.
