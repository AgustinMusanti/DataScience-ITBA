# ANEXO - CÓDIGO R - TP1

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
