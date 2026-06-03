# ============================================================
#  ANALISIS ARIMA MANUAL - HARGA BERAS PREMIUM & MEDIUM
#  Training : Jan 2019 – Jun 2023 (54 bulan)
#  Forecast : Jul – Des 2023 (6 bulan)
#  Validasi : Dibandingkan data aktual Jul–Des 2023
# ============================================================

# ------------------------------------------------------------
# 1. LOAD LIBRARY
# ------------------------------------------------------------
library(readxl)
library(forecast)
library(tseries)
library(ggplot2)
library(gridExtra)
library(ggfortify)

# ------------------------------------------------------------
# 2. LOAD DATA
# ------------------------------------------------------------
# Data training: Jan 2019 – Jun 2023
data_train <- read_excel("HARGA BERAS 2019-2023.xlsx")

# Data aktual (testing): Jul – Des 2023
data_test  <- read_excel("DATA TESTING.xlsx")

cat("=== Data Training ===\n")
print(data_train)
cat(sprintf("\nJumlah data training: %d bulan (%s s.d. %s)\n",
            nrow(data_train),
            format(min(data_train$tanggal), "%b %Y"),
            format(max(data_train$tanggal), "%b %Y")))

cat("\n=== Data Testing (Aktual) ===\n")
print(data_test)

# ------------------------------------------------------------
# 3. KONVERSI KE TIME SERIES
# ------------------------------------------------------------
# Training (Jan 2019 – Jun 2023)
ts_prem_train <- ts(data_train$`harga premium`, start = c(2019, 1), frequency = 12)
ts_med_train  <- ts(data_train$`harga medium`,  start = c(2019, 1), frequency = 12)

# Aktual testing (Jul – Des 2023) - untuk perbandingan
ts_prem_aktual <- ts(data_test$`harga premium`, start = c(2023, 7), frequency = 12)
ts_med_aktual  <- ts(data_test$`harga medium`,  start = c(2023, 7), frequency = 12)

bulan_label <- c("Jul-2023","Agu-2023","Sep-2023","Okt-2023","Nov-2023","Des-2023")


# ============================================================
#  ANALISIS HARGA BERAS PREMIUM
# ============================================================
cat("\n\n========================================\n")
cat("   ANALISIS HARGA BERAS PREMIUM\n")
cat("   Training: Jan 2019 – Jun 2023\n")
cat("========================================\n")

# ------------------------------------------------------------
# 4A. PLOT EKSPLORASI PREMIUM
# ------------------------------------------------------------
ggtsdisplay(ts_prem_train,
            main = "PREMIUM: Time Series, ACF & PACF (Data Training)")
# Perhatikan:
#   - Apakah ada tren? -> kemungkinan perlu differencing (d>0)
#   - ACF turun lambat exponential -> indikasi AR
#   - PACF cut-off di lag k -> p = k
#   - ACF cut-off di lag k -> q = k

# ------------------------------------------------------------
# 5A. UJI STASIONERITAS PREMIUM
# ------------------------------------------------------------
cat("\n--- Uji Stasioneritas PREMIUM (Data Asli) ---\n")
adf_prem  <- adf.test(ts_prem_train)
kpss_prem <- kpss.test(ts_prem_train, null = "Level")

cat(sprintf("ADF Test  : statistik=%.4f, p-value=%.4f  -> %s\n",
            adf_prem$statistic, adf_prem$p.value,
            ifelse(adf_prem$p.value < 0.05, "STASIONER", "TIDAK STASIONER")))
cat(sprintf("KPSS Test : statistik=%.4f, p-value=%.4f  -> %s\n",
            kpss_prem$statistic, kpss_prem$p.value,
            ifelse(kpss_prem$p.value > 0.05, "STASIONER", "TIDAK STASIONER")))

d_prem <- ndiffs(ts_prem_train)
cat(sprintf("Rekomendasi d: %d\n", d_prem))

# ------------------------------------------------------------
# 6A. DIFFERENCING PREMIUM
# ------------------------------------------------------------
ts_prem_diff <- diff(ts_prem_train, differences = d_prem)

cat(sprintf("\n--- ADF Setelah Differencing (d=%d) ---\n", d_prem))
adf_prem_d <- adf.test(ts_prem_diff)
cat(sprintf("ADF p-value = %.4f  -> %s\n",
            adf_prem_d$p.value,
            ifelse(adf_prem_d$p.value < 0.05, "STASIONER ✓", "MASIH TIDAK STASIONER")))

ggtsdisplay(ts_prem_diff,
            main = sprintf("PREMIUM: ACF & PACF Setelah Differencing (d=%d)", d_prem))
# -> Baca plot ini untuk tentukan p (dari PACF) dan q (dari ACF)

# ------------------------------------------------------------
# 7A. GRID SEARCH - PREMIUM
# ------------------------------------------------------------
kandidat_p <- 0:3
kandidat_q <- 0:3

cat(sprintf("\n--- Grid Search ARIMA Premium (d=%d) ---\n", d_prem))
hasil_prem <- data.frame(p=integer(), d=integer(), q=integer(),
                         AIC=numeric(), BIC=numeric())

for (p in kandidat_p) {
  for (q in kandidat_q) {
    tryCatch({
      m <- Arima(ts_prem_train, order = c(p, d_prem, q))
      hasil_prem <- rbind(hasil_prem, data.frame(
        p=p, d=d_prem, q=q,
        AIC=round(AIC(m), 2),
        BIC=round(BIC(m), 2)))
      cat(sprintf("  ARIMA(%d,%d,%d)  AIC=%8.2f  BIC=%8.2f\n",
                  p, d_prem, q, AIC(m), BIC(m)))
    }, error = function(e) NULL)
  }
}

hasil_prem <- hasil_prem[order(hasil_prem$AIC), ]
cat("\nTop 5 Model Premium:\n")
print(head(hasil_prem, 5))

bp <- hasil_prem$p[1]; bd <- hasil_prem$d[1]; bq <- hasil_prem$q[1]
model_prem <- Arima(ts_prem_train, order = c(bp, bd, bq))
cat(sprintf("\nModel Terpilih PREMIUM: ARIMA(%d,%d,%d)\n", bp, bd, bq))
print(summary(model_prem))

cat("\n--- TABEL PARAMETER ESTIMATION (TOP 5) ---\n")

# Loop untuk mengambil detail tiap model dari Top 5
for(i in 1:5) {
  p <- hasil_prem$p[i]
  d <- hasil_prem$d[i]
  q <- hasil_prem$q[i]
  
  # Fit model satu per satu
  temp_model <- Arima(ts_prem_train, order = c(p, d, q))
  
  cat(sprintf("\nModel %d: ARIMA(%d,%d,%d)\n", i, p, d, q))
  print(coef(temp_model)) # Ini untuk AR1, MA1, dsb
  cat(sprintf("Log Likelihood: %.2f\n", temp_model$loglik))
  cat("--------------------------------------------\n")}


cat("\n--- TABEL RESIDUAL ANALYSIS (Ljung-Box Only) ---\n")
# Membuat header tabel agar rapi
cat(sprintf("%-15s | %-15s | %-10s\n", "Model", "Ljung-Box (p)", "Description"))
cat("------------------------------------------------------------\n")

for(i in 1:5) {
  # Mengambil p, d, q dari tabel hasil_prem (Top 5)
  p <- hasil_prem$p[i]; d <- hasil_prem$d[i]; q <- hasil_prem$q[i]
  
  # Fit model sementara
  temp_model <- Arima(ts_prem_train, order = c(p, d, q))
  
  # Hitung Ljung-Box Test
  lb_test <- Box.test(residuals(temp_model), type = "Ljung-Box")
  lb_p_value <- lb_test$p.value
  
  # Logika Description: Accept jika p-value > 0.05
  status <- ifelse(lb_p_value > 0.05, "Accept", "Reject")
  
  # Print baris tabel
  cat(sprintf("%-15s | %-15.4f | %-10s\n", 
              paste0("ARIMA(", p, ",", d, ",", q, ")"), 
              lb_p_value, 
              status))}

# ------------------------------------------------------------
# 8A. DIAGNOSTIK RESIDUAL PREMIUM
# ------------------------------------------------------------
cat("\n--- Diagnostik Residual PREMIUM ---\n")
checkresiduals(model_prem)

lb_prem <- Box.test(residuals(model_prem), lag = 12, type = "Ljung-Box")
cat(sprintf("Ljung-Box p-value = %.4f  -> %s\n",
            lb_prem$p.value,
            ifelse(lb_prem$p.value > 0.05,
                   "Residual WHITE NOISE ✓ Model sudah baik",
                   "Residual TIDAK white noise - pertimbangkan order lain")))

# ------------------------------------------------------------
# 9A. FORECAST PREMIUM (Jul–Des 2023)
# ------------------------------------------------------------
fc_prem <- forecast(model_prem, h = 6)

# Hitung APE tiap bulan dan MAPE
ape_prem  <- abs(as.numeric(ts_prem_aktual) - as.numeric(fc_prem$mean)) /
  as.numeric(ts_prem_aktual) * 100
mape_prem <- mean(ape_prem)

df_result_prem <- data.frame(
  Bulan    = bulan_label,
  Forecast = round(as.numeric(fc_prem$mean), 0),
  Lo80     = round(as.numeric(fc_prem$lower[,1]), 0),
  Hi80     = round(as.numeric(fc_prem$upper[,1]), 0),
  Lo95     = round(as.numeric(fc_prem$lower[,2]), 0),
  Hi95     = round(as.numeric(fc_prem$upper[,2]), 0),
  Aktual   = as.numeric(ts_prem_aktual),
  Selisih  = as.numeric(ts_prem_aktual) - round(as.numeric(fc_prem$mean), 0),
  APE_pct  = round(ape_prem, 2)
)

cat("\n--- Hasil Forecast vs Aktual PREMIUM ---\n")
print(df_result_prem)
cat(sprintf("\nMAPE Premium: %.2f%%  %s\n", mape_prem,
            ifelse(mape_prem < 10, "(Sangat Baik ✓)",
                   ifelse(mape_prem < 20, "(Baik)", "(Perlu Review)"))))


# ============================================================
#  ANALISIS HARGA BERAS MEDIUM
# ============================================================
cat("\n\n========================================\n")
cat("   ANALISIS HARGA BERAS MEDIUM\n")
cat("   Training: Jan 2019 – Jun 2023\n")
cat("========================================\n")

# ------------------------------------------------------------
# 4B. PLOT EKSPLORASI MEDIUM
# ------------------------------------------------------------
ggtsdisplay(ts_med_train,
            main = "MEDIUM: Time Series, ACF & PACF (Data Training)")

# ------------------------------------------------------------
# 5B. UJI STASIONERITAS MEDIUM
# ------------------------------------------------------------
cat("\n--- Uji Stasioneritas MEDIUM (Data Asli) ---\n")
adf_med  <- adf.test(ts_med_train)
kpss_med <- kpss.test(ts_med_train, null = "Level")

cat(sprintf("ADF Test  : statistik=%.4f, p-value=%.4f  -> %s\n",
            adf_med$statistic, adf_med$p.value,
            ifelse(adf_med$p.value < 0.05, "STASIONER", "TIDAK STASIONER")))
cat(sprintf("KPSS Test : statistik=%.4f, p-value=%.4f  -> %s\n",
            kpss_med$statistic, kpss_med$p.value,
            ifelse(kpss_med$p.value > 0.05, "STASIONER", "TIDAK STASIONER")))

d_med <- ndiffs(ts_med_train)
cat(sprintf("Rekomendasi d: %d\n", d_med))

# ------------------------------------------------------------
# 6B. DIFFERENCING MEDIUM
# ------------------------------------------------------------
ts_med_diff <- diff(ts_med_train, differences = d_med)

cat(sprintf("\n--- ADF Setelah Differencing (d=%d) ---\n", d_med))
adf_med_d <- adf.test(ts_med_diff)
cat(sprintf("ADF p-value = %.4f  -> %s\n",
            adf_med_d$p.value,
            ifelse(adf_med_d$p.value < 0.05, "STASIONER ✓", "MASIH TIDAK STASIONER")))

ggtsdisplay(ts_med_diff,
            main = sprintf("MEDIUM: ACF & PACF Setelah Differencing (d=%d)", d_med))

# ------------------------------------------------------------
# 7B. GRID SEARCH - MEDIUM
# ------------------------------------------------------------
cat(sprintf("\n--- Grid Search ARIMA Medium (d=%d) ---\n", d_med))
hasil_med <- data.frame(p=integer(), d=integer(), q=integer(),
                        AIC=numeric(), BIC=numeric())

for (p in kandidat_p) {
  for (q in kandidat_q) {
    tryCatch({
      m <- Arima(ts_med_train, order = c(p, d_med, q))
      hasil_med <- rbind(hasil_med, data.frame(
        p=p, d=d_med, q=q,
        AIC=round(AIC(m), 2),
        BIC=round(BIC(m), 2)))
      cat(sprintf("  ARIMA(%d,%d,%d)  AIC=%8.2f  BIC=%8.2f\n",
                  p, d_med, q, AIC(m), BIC(m)))
    }, error = function(e) NULL)
  }
}

hasil_med <- hasil_med[order(hasil_med$AIC), ]
cat("\nTop 5 Model Medium:\n")
print(head(hasil_med, 5))

mp <- hasil_med$p[1]; md2 <- hasil_med$d[1]; mq <- hasil_med$q[1]
model_med <- Arima(ts_med_train, order = c(mp, md2, mq))
cat(sprintf("\nModel Terpilih MEDIUM: ARIMA(%d,%d,%d)\n", mp, md2, mq))
print(summary(model_med))


cat("\n--- TABEL PARAMETER ESTIMATION MEDIUM (TOP 5) ---\n")

for(i in 1:5) {
  p <- hasil_med$p[i]; d <- hasil_med$d[i]; q <- hasil_med$q[i]
  
  # Fit model Medium
  model_temp_med <- Arima(ts_med_train, order = c(p, d, q))
  
  cat(sprintf("\nModel %d: ARIMA(%d,%d,%d)\n", i, p, d, q))
  print(coef(model_temp_med)) # Untuk AR1, MA1, dsb
  cat(sprintf("Log Likelihood: %.2f\n", model_temp_med$loglik))
  cat("--------------------------------------------\n")}

cat("\n--- TABEL RESIDUAL ANALYSIS MEDIUM (Ljung-Box Only) ---\n")
cat(sprintf("%-15s | %-15s | %-10s\n", "Model", "Ljung-Box (p)", "Description"))
cat("------------------------------------------------------------\n")

for(i in 1:5) {
  p <- hasil_med$p[i]; d <- hasil_med$d[i]; q <- hasil_med$q[i]
  
  model_temp_med <- Arima(ts_med_train, order = c(p, d, q))
  
  # Hitung Ljung-Box Test
  lb_test_med <- Box.test(residuals(model_temp_med), type = "Ljung-Box")
  lb_p_med <- lb_test_med$p.value
  
  # Deskripsi Accept jika > 0.05
  status_med <- ifelse(lb_p_med > 0.05, "Accept", "Reject")
  
  cat(sprintf("%-15s | %-15.4f | %-10s\n", 
              paste0("ARIMA(", p, ",", d, ",", q, ")"), 
              lb_p_med, 
              status_med))}

# ------------------------------------------------------------
# 8B. DIAGNOSTIK RESIDUAL MEDIUM
# ------------------------------------------------------------
cat("\n--- Diagnostik Residual MEDIUM ---\n")
checkresiduals(model_med)

lb_med <- Box.test(residuals(model_med), lag = 12, type = "Ljung-Box")
cat(sprintf("Ljung-Box p-value = %.4f  -> %s\n",
            lb_med$p.value,
            ifelse(lb_med$p.value > 0.05,
                   "Residual WHITE NOISE ✓ Model sudah baik",
                   "Residual TIDAK white noise - pertimbangkan order lain")))

# ------------------------------------------------------------
# 9B. FORECAST MEDIUM (Jul–Des 2023)
# ------------------------------------------------------------
fc_med <- forecast(model_med, h = 6)

ape_med  <- abs(as.numeric(ts_med_aktual) - as.numeric(fc_med$mean)) /
  as.numeric(ts_med_aktual) * 100
mape_med <- mean(ape_med)

df_result_med <- data.frame(
  Bulan    = bulan_label,
  Forecast = round(as.numeric(fc_med$mean), 0),
  Lo80     = round(as.numeric(fc_med$lower[,1]), 0),
  Hi80     = round(as.numeric(fc_med$upper[,1]), 0),
  Lo95     = round(as.numeric(fc_med$lower[,2]), 0),
  Hi95     = round(as.numeric(fc_med$upper[,2]), 0),
  Aktual   = as.numeric(ts_med_aktual),
  Selisih  = as.numeric(ts_med_aktual) - round(as.numeric(fc_med$mean), 0),
  APE_pct  = round(ape_med, 2)
)

cat("\n--- Hasil Forecast vs Aktual MEDIUM ---\n")
print(df_result_med)
cat(sprintf("\nMAPE Medium: %.2f%%  %s\n", mape_med,
            ifelse(mape_med < 10, "(Sangat Baik ✓)",
                   ifelse(mape_med < 20, "(Baik)", "(Perlu Review)"))))


# ============================================================
#  VISUALISASI
# ============================================================

# --- Plot 1: Forecast Premium vs Aktual ---
# --- Plot 1: Forecast Premium vs Aktual ---
p1 <- autoplot(fc_prem) +
  autolayer(ts_prem_aktual, series = "Aktual Jul-Des 2023", linewidth = 1.2) +
  ggtitle(sprintf("Harga Beras PREMIUM | ARIMA(%d,%d,%d) | MAPE = %.2f%%",
                  bp, bd, bq, mape_prem)) +
  xlab("Tahun") + ylab("Harga (Rp)") +
  scale_colour_manual(values = c("Aktual Jul-Des 2023" = "#D85A30", "forecast" = "#378ADD")) +
  labs(colour = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 11),
        legend.position = "bottom")

# --- Plot 2: Forecast Medium vs Aktual ---
p2 <- autoplot(fc_med) +
  autolayer(ts_med_aktual, series = "Aktual Jul-Des 2023", linewidth = 1.2) +
  ggtitle(sprintf("Harga Beras MEDIUM | ARIMA(%d,%d,%d) | MAPE = %.2f%%",
                  mp, md2, mq, mape_med)) +
  xlab("Tahun") + ylab("Harga (Rp)") +
  scale_colour_manual(values = c("Aktual Jul-Des 2023" = "#D85A30", "forecast" = "#1D9E75")) +
  labs(colour = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 11),
        legend.position = "bottom")

grid.arrange(p1, p2, nrow = 2)

# --- Plot 3: Line chart Forecast vs Aktual per bulan (Premium) ---
df_line_prem <- data.frame(
  Bulan    = factor(bulan_label, levels = bulan_label),
  Forecast = as.numeric(df_result_prem$Forecast),
  Aktual   = as.numeric(df_result_prem$Aktual)
)
p3 <- ggplot(df_line_prem, aes(x = Bulan, group = 1)) +
  geom_line(aes(y = Forecast, colour = "Forecast"), linewidth = 1.2, linetype = "dashed") +
  geom_line(aes(y = Aktual,   colour = "Aktual"),    linewidth = 1.2) +
  geom_point(aes(y = Forecast, colour = "Forecast"), size = 3) +
  geom_point(aes(y = Aktual,   colour = "Aktual"),   size = 3) +
  scale_colour_manual(values = c("Forecast" = "#378ADD", "Aktual" = "#D85A30")) +
  ggtitle(sprintf("PREMIUM: Forecast vs Aktual | MAPE=%.2f%%", mape_prem)) +
  xlab(NULL) + ylab("Harga (Rp)") + labs(colour = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")

# --- Plot 4: Line chart Forecast vs Aktual per bulan (Medium) ---
df_line_med <- data.frame(
  Bulan    = factor(bulan_label, levels = bulan_label),
  Forecast = as.numeric(df_result_med$Forecast),
  Aktual   = as.numeric(df_result_med$Aktual)
)
p4 <- ggplot(df_line_med, aes(x = Bulan, group = 1)) +
  geom_line(aes(y = Forecast, colour = "Forecast"), linewidth = 1.2, linetype = "dashed") +
  geom_line(aes(y = Aktual,   colour = "Aktual"),    linewidth = 1.2) +
  geom_point(aes(y = Forecast, colour = "Forecast"), size = 3) +
  geom_point(aes(y = Aktual,   colour = "Aktual"),   size = 3) +
  scale_colour_manual(values = c("Forecast" = "#1D9E75", "Aktual" = "#D85A30")) +
  ggtitle(sprintf("MEDIUM: Forecast vs Aktual | MAPE=%.2f%%", mape_med)) +
  xlab(NULL) + ylab("Harga (Rp)") + labs(colour = NULL) +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")

grid.arrange(p3, p4, nrow = 2)

# --- Plot 5: Gabungan (Tidak ada perubahan signifikan, hanya pastikan scale_manual aman) ---
autoplot(ts_all_prem, series = "Premium Historis") +
  autolayer(ts_all_med,      series = "Medium Historis") +
  autolayer(fc_prem$mean,    series = "Forecast Premium") +
  autolayer(fc_med$mean,     series = "Forecast Medium") +
  autolayer(ts_prem_aktual,  series = "Aktual Premium") +
  autolayer(ts_med_aktual,   series = "Aktual Medium") +
  scale_colour_manual(values = c(
    "Premium Historis" = "#185FA5",
    "Medium Historis"  = "#1D9E75",
    "Forecast Premium" = "#85B7EB",
    "Forecast Medium"  = "#9FE1CB",
    "Aktual Premium"   = "#D85A30",
    "Aktual Medium"    = "#854F0B"
  )) +
  ggtitle("Historis | Forecast | Aktual – Premium & Medium (2019–2023)") +
  xlab("Tahun") + ylab("Harga (Rp)") + labs(colour = "Keterangan") +
  theme_bw(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")


# ============================================================
#  RINGKASAN AKHIR
# ============================================================
cat("\n\n============================================\n")
cat("          RINGKASAN HASIL ANALISIS\n")
cat("============================================\n")
cat(sprintf("Data Training  : Jan 2019 – Jun 2023 (%d bulan)\n", nrow(data_train)))
cat(sprintf("Periode Forecast: Jul – Des 2023 (6 bulan)\n"))
cat(sprintf("\nModel PREMIUM  : ARIMA(%d,%d,%d)\n", bp, bd, bq))
cat(sprintf("  AIC          : %.2f\n", AIC(model_prem)))
cat(sprintf("  Ljung-Box p  : %.4f (%s)\n", lb_prem$p.value,
            ifelse(lb_prem$p.value > 0.05, "OK ✓", "Perlu review")))
cat(sprintf("  MAPE         : %.2f%% (%s)\n", mape_prem,
            ifelse(mape_prem < 10, "Sangat Baik",
                   ifelse(mape_prem < 20, "Baik", "Perlu Review"))))
cat(sprintf("\nModel MEDIUM   : ARIMA(%d,%d,%d)\n", mp, md2, mq))
cat(sprintf("  AIC          : %.2f\n", AIC(model_med)))
cat(sprintf("  Ljung-Box p  : %.4f (%s)\n", lb_med$p.value,
            ifelse(lb_med$p.value > 0.05, "OK ✓", "Perlu review")))
cat(sprintf("  MAPE         : %.2f%% (%s)\n", mape_med,
            ifelse(mape_med < 10, "Sangat Baik",
                   ifelse(mape_med < 20, "Baik", "Perlu Review"))))
cat("============================================\n")

# --- Ekspor Hasil ke CSV ---


write.csv(df_result_prem, "Hasil_Forecast_Premium.csv", row.names = FALSE)
write.csv(df_result_med, "Hasil_Forecast_Medium.csv", row.names = FALSE)

cat("\n[INFO] File CSV berhasil dibuat di folder kerja Anda!\n")
cat("Silakan cek file: Hasil_Forecast_Premium.csv dan Hasil_Forecast_Medium.csv\n")