# Carga de la librería y del dataset cheddar 

library(faraway) 

data(cheddar) 

# Documentación de la base y sus variables 

?cheddar 

# Punto 2 - Resumen de la base 

summary(cheddar) 

# Punto 3 - Agrupamiento k-means 

# Como semilla utilizo mi DNI(xxxx5505), cantidad de grupos = 4 

# Resto de los parámetros por defecto 

set.seed(xxxx5505); km = kmeans(cheddar, 4) 

# Punto 4 - Cantidad de elementos por grupo 

km$size

# Punto 5 - Grupo asignado a cada observación 

km$cluster 

# Punto 6 - Centroides de cada grupo 

km$centers
