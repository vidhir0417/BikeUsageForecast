##########################################################################
##                        Data set File Path                             ##
##########################################################################
setwd("C:/Users/Vidhi Rajanikante/OneDrive/Documents/R Studio/FM/Project/FM Project - Final")

##########################################################################
##                          Library Imports                             ##
########################################################################## 

library(openxlsx)
library(fpp3)
library(tsibble)
library(tseries)
library(dbplyr)
library(forecast)
library(ggplot2)
library(urca)
library(tidyverse)
library(fable)
library(lubridate)
library(feasts)


##########################################################################
##                        Treating the Dataset                          ##
##########################################################################

summ_data <- read.csv("FM Summarized Data.csv")
summ_data %>% View()

monthly_tsibble <- summ_data %>% 
                    mutate(month = yearmonth(month)) %>% 
                    as_tsibble(index = month)

monthly_tsibble %>% 
  autoplot() + 
  labs(title = 'MiBici Usage in ZMG', 
       y = 'Total amount of Public Bikes used') + 
  scale_y_continuous(limits = c(0, 500000), breaks = seq(0, 500000, 50000))

monthly_tsibble %>% 
  autoplot(log(Count)) + 
  labs(title = 'MiBici Usage in ZMG') 


##########################################################################
##             Splitting our Summarized Data for Forecast               ##
##########################################################################

n <- nrow(monthly_tsibble)
training <- monthly_tsibble %>% slice(1:(n-12))
test <- monthly_tsibble %>% slice((n-12):n)


##########################################################################
##                         Applying ADF Test                            ##
##########################################################################

summary(ur.df(na.omit(monthly_tsibble$Count), type=c("trend"), lags=3))

first_seasonal_diff <- log(monthly_tsibble$Count) %>%  
  difference(lag=12) %>%
  difference()

summary(ur.df(na.omit(first_seasonal_diff), type="none", lags=0))


##########################################################################
##                 Model Identification & Analysis                      ##
##########################################################################

monthly_tsibble %>%
  gg_tsdisplay(difference(Count, 1), 
               plot_type = "partial", lag_max = 37)
# ARIMA (1,1,1)
# SARIMA(1,1,1)(1,0,0)

monthly_tsibble %>%
  gg_tsdisplay(difference(log(Count), 1), 
               plot_type = "partial", lag_max = 49)
# SARIMA(0,1,0)(1,0,2)

monthly_tsibble %>% 
  gg_tsdisplay(log(Count) %>%
                 difference(lag=12) %>%
                 difference(), plot_type = "partial", lag_max = 49)
# SARIMA(0,1,0)(2,1,1)
# SARIMA(0,1,0)(1,1,1)


##########################################################################
##               Model's Residual Analysis & LB Test                    ##
##########################################################################

fit1 <- monthly_tsibble %>%
  model(sarima_102 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,0,2)))
fit1 %>% report()
fit1 %>% gg_tsresiduals()

augment(fit1) %>% 
  features(.innov, ljung_box, lag = 12)

fit2 <- monthly_tsibble %>%
  model(sarima_111 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,1,1)))
fit2 %>% report()
fit2 %>% gg_tsresiduals()

augment(fit2) %>% 
  features(.innov, ljung_box, lag = 12)


##########################################################################
##                          Model Evaluation                            ##
##########################################################################

# Fitting the models to check which models are the best
fit <- monthly_tsibble %>% 
  model(arima_111 = ARIMA(Count ~ 1 + pdq(0,1,1)),
        sarima_100 = ARIMA(Count ~ 1 + pdq(1,1,1) + PDQ(1,0,0)),
        sarima_102 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,0,2)),
        sarima_211 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(2,1,1)),
        sarima_111 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,1,1))
        )

# Checking the criteria of each model to check the best one(s) 
fit %>%
glance() %>%
arrange(AICc) %>%
select(.model:BIC)

# The best models
best_fits <- monthly_tsibble %>%
  model(sarima_102 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,0,2)),
        sarima_211 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(2,1,1)),
        sarima_111 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,1,1)))

best_fits %>% 
  glance() %>%
  arrange(AICc) %>% 
  select(.model:BIC)


##########################################################################
##                          Forecast Checks                             ##
##########################################################################

monthly_train <- training %>%
  model(sarima_111 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,1,1)),
        sarima_211 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(2,1,1)), 
        sarima_102 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,0,2)),
        snaive = SNAIVE(log(Count)), 
        naive = NAIVE(log(Count)), 
        rw = RW(Count ~ drift()))

forecasts <- monthly_train %>%
  forecast(h = 24)

View(accuracy(forecasts, test) %>% 
       arrange(.model) %>% 
       select(.model, .type, RMSE, MAE, MAPE))

forecasts %>%
  autoplot(training) +
  autolayer(test, Count, color = "blue") +
  labs(title = 'MiBici Usage in ZMG',
       x = "Months [1M]",
       y = "Count")


##########################################################################
##                           Final Forecast                             ##
##########################################################################

best_model <- training %>% 
  model(sarima_111 = ARIMA(log(Count) ~ 1 + pdq(0,1,0) + PDQ(1,1,1)))

forecast <- best_model %>% 
  forecast(h=24)

forecast %>%
  autoplot(training) +
  autolayer(test, Count, color = "black") +
  labs(title = "MiBici Usage in ZMG: Forecast of SARIMA(0,1,0)(1,1,1)",
       x = "Months [1M]",
       y = "Count")
