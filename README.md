# Rice Price Forecasting Using ARIMA

Forecasting monthly premium and medium rice prices in Indonesia
using time series analysis (ARIMA) in R.

## Background
Rice price fluctuations directly affect inflation and household
purchasing power in Indonesia. Accurate short-term forecasting
supports government intervention and market stability decisions.

## Data
- **Source:** Badan Pangan Nasional (BPN)
- **Period:** January 2019 – June 2023 (54 months)
- **Variables:** Premium rice price, Medium rice price (IDR/kg)
- **Split:** 48 months training / 6 months testing (Jul–Dec 2023)

## Tools & Methods
- **Language:** R (RStudio)
- **Libraries:** forecast, tseries, ggplot2
- **Method:** Box-Jenkins ARIMA
  - Stationarity testing: ADF + KPSS test
  - Model selection: Grid search over 16 ARIMA candidates (AIC/BIC)
  - Residual validation: Ljung-Box test

## Results
| Series  | Best Model     | MAPE  | Verdict     |
|---------|----------------|-------|-------------|
| Premium | ARIMA(1, 2, 1) | 4.60% | Excellent ✓ |
| Medium  | ARIMA(1, 2, 1) | 5.50% | Excellent ✓ |

Both models passed the residual white noise test (Ljung-Box p > 0.05),
confirming model adequacy.

## Files
- `FINAL_ARIMA.R` — full analysis script (data prep, modeling, forecast,
  visualization)
- `Journal_Rice_Prices` — research paper published at Proceedings of the
  Fifth Symposium on Data Science 2026
