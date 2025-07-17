# Public Bike Usage in Jalisco, Mexico: A Box-Jenkins Forecasting Study

This document analyzes nearly a decade of public bike trip data from MiBici in Guadalajara's metropolitan area (ZMG) to understand and forecast usage trends.

## Introduction

A dataset, obtained from *Kaggle*, of 25,863,690 public bike trips from 372 stations of MiBici in Guadalajara, Jalisco, Mexico, spanning from December 2014 to January 2024 is utilized. The primary goal is to apply the Box-Jenkins Methodology to forecast past and future public bike usage, observing its continuous behavior and trends in the ZMG.

## Data

* **Source:** Public bike use data 2014-2024 (MiBici) from Kaggle.
* **Preprocessing:** The daily captured data was summarized into monthly data, resulting in 110 observations.
* **Key Observation:** The influence of COVID-19 is evident as a significant drop in usage in the initial plot.

## Methodology (Box-Jenkins Forecasting)

The project followed the Box-Jenkins Methodology, involving several key steps:

### 1. Data Division
* The dataset was divided into a training set (December 2014 to January 2023) and a test set (the last year of the dataset).

### 2. Data Transformation
* **Log Transformation:** Applied to deal with variance within the dataset and ensure stability.
* **Differencing:** Both seasonal and normal differences were applied to achieve stationarity, supported by the unit root (ADF) test.

### 3. ARIMA Model Identification
* Autocorrelation (ACF) and Partial Autocorrelation (PACF) functions were analyzed to suggest model orders.
* Candidate models included AR models of order 1 or 2 and an MA model of order 1.
* The `sarima_111` (SARIMA(0,1,0)(1,1,1)) model was identified as a strong candidate.

### 4. Model Validation
* **Ljung-Box Test:** Performed to confirm no autocorrelation in the residuals and normal distribution, indicating a good fit for the data.

### 5. Model Comparison and Selection
* Various models, including `naive`, `seasonal naive`, `random walk`, `sarima_102`, `sarima_111` and `sarima_211`, were tested.
* Accuracy scores (RIMSE, MAE, MAPE) were calculated on the test set.
* `sarima_111` and `sarima_211` showed similar values, but `sarima_111` was preferred due to its more stable forecast and less overestimation compared to other models.

## Results and Conclusions

* The `sarima_111` model (SARIMA(0,1,0)(1,1,1)) was deemed a good enough model for predicting public bike usage in Guadalajara's metropolitan area.
* The model's forecast ranges (at 80% or 95% levels) are not as large compared to other models, and its predictions are similar to actual data.
* Despite the impact of COVID-19, which caused a significant drop in usage and potentially biased estimates, public bike usage is shown to be gradually picking up.
* The project suggests that the increase in usage is likely due to more people commuting to places further away from the metro for efficiency and time-saving.

## References

* [1] Kaggle. (2024). Public bike use data 2014-2024 (MiBici). `https://www.kaggle.com/datasets/sebastianquirarte/over-9-years-of-real-public-bike-use-data-mibici/code`
* [2] MiBici. (2024). Datos ABiertos. `https://www.mibici.net/es/datos-abiertos/`
* [3] Minitab. (Unknown). Interpret the key results for forecast with Best ARIMA Model. `https://support.minitab.com/en-us/minitab/help-and-how-to/statistical-modeling/time-series/how-to/forecast-with-best-arima-model/interpret-the-results/key-results/`
* [4] Hyndman, R. J., & Athanasopoulos, G. (2023, June 8). Evaluating forecast accuracy. `https://otexts.com/fpp2/accuracy.html`
