# OFDM ICI Self-Cancellation — MATLAB Simulation

> **Academic project** | Signal Processing / Wireless Communications  
> Originally written ~2012, updated 2024 for modern MATLAB (R2014b+).

---

## Overview

This project simulates **Inter-Carrier Interference (ICI) reduction in OFDM systems** using the **ICI Self-Cancellation (SC) scheme** proposed by Zhao & Häggman (2001).

OFDM is highly sensitive to carrier frequency offsets (CFO) caused by Doppler shift or local oscillator mismatch. A CFO destroys orthogonality between subcarriers, creating ICI that degrades BER performance. This project evaluates:

1. BER of a **standard OFDM** system under various CFOs and QAM orders
2. BER improvement using **ICI Self-Cancellation**
3. Theoretical **ICI coefficients** and **Carrier-to-Interference Ratio (CIR)** curves
4. **Maximum Likelihood Estimation (MLE)** for frequency offset correction

---

## Repository Structure

```
ofdm_ici_project/
│
├── matlab/
│   ├── run_all.m                  ← Master script (run this first)
│   ├── run_standard_ofdm.m        ← Standard OFDM BER simulator
│   ├── run_ici_sc_ofdm.m          ← ICI Self-Cancellation BER simulator
│   ├── run_mle_ofdm.m             ← MLE frequency offset correction
│   ├── sici.m                     ← ICI coefficient & CIR theory plots
│   └── complex_ICI_coefficient.m  ← |S(l-k)| magnitude plot
│
├── results/                       ← Auto-generated .mat files (BER data)
│
└── README.md
```

---

## How to Run

1. Open MATLAB (R2014b or newer recommended)
2. Navigate to the `matlab/` folder
3. Run the master script:

```matlab
run_all
```

This will:
- Simulate BER for QAM-2, 4, 16, 64 (standard and SC)
- Save results to `results/`
- Generate all comparison plots

To run only the theoretical ICI plots:
```matlab
sici
complex_ICI_coefficient
```

---

## Simulation Parameters

| Parameter              | Value                   |
|------------------------|-------------------------|
| OFDM subcarriers       | 52                      |
| FFT/IFFT size          | 64                      |
| OFDM symbols per run   | 100                     |
| Channel model          | AWGN                    |
| Modulation             | QAM-2, 4, 16, 64        |
| Frequency offsets (ε)  | 0, 0.15, 0.3 (normalised)|
| Eb/No range            | 1–30 dB                 |

---

## ICI Self-Cancellation Scheme

**Modulation:** Each data symbol `d` is mapped onto a subcarrier pair `(k, k+1)`:
- `X(k)   =  d`
- `X(k+1) = -d`

**Demodulation:** The pair is combined at the receiver:
- `d̂ = 0.5 × (Y(k) − Y(k+1))`

This causes ICI components from adjacent subcarriers to cancel, improving CIR by >15 dB for `0 < ε < 0.5`. The cost is **50% spectral efficiency** (2 subcarriers per data symbol).

---

## Key Results

- ICI self-cancellation improves BER performance for all QAM orders
- Improvement is most significant at lower modulation orders (QAM-2, QAM-4)
- CIR improvement exceeds 15 dB across the practical frequency offset range
- For higher modulation orders (QAM-64), the scheme still helps but residual ICI limits performance

---

## Code Changes from Original (2012)

The original code used legacy MATLAB Communications Toolbox objects that are no longer supported:

| Original (broken)               | Updated                                  |
|---------------------------------|------------------------------------------|
| `modem.qammod(M)` + `modulate()`| `qammod(data, M, 'UnitAveragePower',true)`|
| `modem.qamdemod(M)` + `demodulate()` | `qamdemod(data, M, 'UnitAveragePower',true)` |
| `dmodce()` / `ddemodce()`       | Replaced with `qammod`/`qamdemod`        |
| Hardcoded `reshape(...,10,[])`  | Uses `log2(M)` bits per symbol correctly |
| Fixed BER denominator (5200)    | Uses `totalBits = numCarriers*NS*log2(M)`|
| Fixed EsNo=15 scalar            | Full `EbNo = 1:30` sweep                 |
| Scripts (no functions)          | Refactored as functions with clear I/O   |

---

## References

1. Y. Zhao and S.-G. Häggman, "Intercarrier interference self-cancellation scheme for OFDM mobile communication systems," *IEEE Trans. Commun.*, vol. 49, no. 7, pp. 1185–1191, Jul. 2001.
2. P. H. Moose, "A technique for orthogonal frequency division multiplexing frequency offset correction," *IEEE Trans. Commun.*, vol. 42, no. 10, pp. 2908–2914, Oct. 1994.
3. R. Li and G. Stette, "Time-limited orthogonal multicarrier modulation schemes," *IEEE Trans. Commun.*, vol. 43, Feb./Mar./Apr. 1995.

---

## License

This code is shared for educational reference. Feel free to use and adapt with attribution.
