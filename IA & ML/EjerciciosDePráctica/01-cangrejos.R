# Análisis exploratorio dataset cangrejos
# Autor: Agustín Musanti

library(caret)

# Cargar dataset
base <- read.table("datasetCangre.csv", sep = ",", header = TRUE)

# Inspección
head(base)
str(base)

# Gráfico CW vs CL agrupado por especie
xyplot(CW ~ CL, base, groups = Especie, auto.key = TRUE, pch = 19)
