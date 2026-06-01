# ANEXO - CÓDIGO R - TP1 + Regresión Lineal

# Parte A - Regresión 

# Carga de librería y dataset

library(ISLR2) 

data(Credit)

# Dimensiones y resumen estadístico de la base 

dim(Credit)

summary(Credit) 

# Histograma de la variable a predecir (Balance) 

hist(Credit$Balance, main = "Histograma de Agustín", col = "steelblue") 

# Parte B - Conjuntos 

# Carga de librería caret para la partición 

library(caret) 

# Partición en conjunto de entrenamiento (75%) y testeo (25%) 

# Semilla: DNI 

set.seed(xxxx5505); particion = createDataPartition(y = Credit$Balance, p = 
0.75, list = FALSE) 

entreno = Credit[particion, ] 

testeo = Credit[-particion, ] 

# Exploración del conjunto de entrenamiento 

head(entreno) 

summary(entreno) 

# Exploración del conjunto de testeo 

head(testeo) 

summary(testeo) 

# Cantidad de registros en cada conjunto 

dim(entreno)

dim(testeo) 

# Parte C - Modelo predictivo de Regresión Lineal

# Entrenamiento del modelo lineal con 3 predictores económicos: 

# Limit, Rating e Income 

modelo = lm(Balance ~ Limit + Rating + Income, data = entreno) 

summary(modelo) 

# Predicción sobre el conjunto de testeo 

pred = predict(modelo, newdata = testeo) 

# Métricas de error 

mse = mean((testeo$Balance - pred)^2) 

rmse = sqrt(mse) 

cat("MSE del modelo en testeo:", round(mse, 2), "\n") 

cat("RMSE:", round(rmse, 2), "USD\n") 

# Gráfico predicho vs real 

plot(testeo$Balance, pred, 
main = "Predicho vs Real - Modelo Lineal", 
xlab = "Balance real (USD)", 
ylab = "Balance predicho (USD)", 
col = "steelblue", 
pch = 19) 

abline(0, 1, col = "red", lwd = 2, lty = 2)
