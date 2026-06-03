# ============================================================
# IA y Machine Learning - ITBA
# TP: Carga de archivos + Árbol de decisión
# Dataset: Advertising.csv (ISLR, Hastie et al.)
# ============================================================

# ------------------------------------------------------------
# Inciso 0 - Directorio de trabajo
# ------------------------------------------------------------
# R busca los archivos en el "working directory". Hay que pararlo
# en la carpeta donde está el .csv (equivale a hacer os.chdir() en Python).
# En RGui:    Archivo -> Cambiar Dir...
# En RStudio: Session -> Set Working Directory -> Choose Directory
# Para chequear dónde está parado:
getwd()


# ------------------------------------------------------------
# Inciso 1 - Carga con read.table (sin parámetros)
# ------------------------------------------------------------
# read.table por defecto NO sabe que el separador es coma ni que
# hay encabezado. Va a meter toda la fila en una sola columna.
base <- read.table("Advertising.csv")
head(base)
# Resultado esperado: una sola columna con todo apelmazado ("1,230.1,37.8,...").
# Falta indicarle el separador.


# ------------------------------------------------------------
# Inciso 2 - read.table indicando el separador
# ------------------------------------------------------------
# Ahora sí separa por coma, pero toma la primera fila (los nombres
# TV, radio, etc.) como si fueran un dato más -> los nombres de columna
# quedan como V1, V2, V3...
base <- read.table("Advertising.csv", sep = ",")
head(base)
# Falta avisarle que la primera fila es el encabezado.


# ------------------------------------------------------------
# Inciso 3 - read.table con separador + header
# ------------------------------------------------------------
# header = TRUE le dice que la primera fila son los NOMBRES de las
# columnas, no datos. Ahora la base queda bien cargada.
base <- read.table("Advertising.csv", sep = ",", header = TRUE)
head(base)
# "header" sirve para que R use la primera fila como nombres de columna
# (en pandas es el parámetro header= de read_csv, que por defecto ya es 0).


# ------------------------------------------------------------
# Inciso 4 - Carga directa con read.csv (la forma corta)
# ------------------------------------------------------------
# read.csv es read.table pero con los defaults ya seteados para CSV:
# sep = "," y header = TRUE. Por eso anda de una.
base <- read.csv("Advertising.csv")
head(base)


# ------------------------------------------------------------
# Inciso 5 - Limpieza y exploración rápida
# ------------------------------------------------------------
# El CSV de ISLR trae una primera columna sin nombre que es solo un
# índice de fila (1, 2, 3...). R la nombra "X". No aporta nada al modelo,
# así que la eliminamos (asignarle NULL borra la columna).
base$X <- NULL

str(base)       # estructura y tipo de cada columna (como base.info() en pandas)
summary(base)   # resumen estadístico (como base.describe())
head(base)
# Quedan 4 columnas:
#   TV, radio, newspaper -> presupuesto de publicidad por canal (predictoras)
#   sales                -> ventas (variable a predecir, es CONTINUA)


# ------------------------------------------------------------
# Inciso 6 - Árbol de decisión (regresión)
# ------------------------------------------------------------
# Como "sales" es numérica continua, corresponde un árbol de REGRESIÓN
# (method = "anova"). Si fuera una categoría, usaríamos method = "class".
# Instalar los paquetes solo la primera vez (descomentar):
# install.packages(c("rpart", "rpart.plot"))

library(rpart)        # algoritmo del árbol (CART)
library(rpart.plot)   # para graficarlo lindo

# La fórmula "sales ~ TV + radio + newspaper" se lee como:
# "explicar sales en función de TV, radio y newspaper".
# Atajo equivalente: sales ~ .  (el punto = "todas las demás columnas")
arbol <- rpart(sales ~ TV + radio + newspaper,
               data   = base,
               method = "anova")


# ------------------------------------------------------------
# Inciso 7 - Visualización del árbol
# ------------------------------------------------------------
rpart.plot(arbol,
           type        = 4,        # muestra la condición en cada rama
           extra       = 101,      # agrega valor predicho + % de datos por nodo
           box.palette = "Blues",
           main        = "Árbol de regresión - Sales")
# Cómo leerlo: cada nodo se parte según una variable y un umbral.
# En las HOJAS, el número es la venta promedio predicha para los casos
# que caen ahí. Vas a ver que TV y radio dominan los cortes y newspaper
# casi no aparece (aporta poco).


# ------------------------------------------------------------
# Inciso 8 - Interpretación numérica del árbol
# ------------------------------------------------------------
print(arbol)     # reglas de cada corte en texto
printcp(arbol)   # tabla de complejidad (cp) y error por nivel del árbol
summary(arbol)   # detalle de cada split + importancia de variables


# ------------------------------------------------------------
# Inciso 9 (opcional) - Poda y predicción
# ------------------------------------------------------------
# rpart hace validación cruzada interna y reporta el error (xerror) por
# cada valor de complejidad (cp). Elegimos el cp con menor xerror para
# podar el árbol y evitar sobreajuste.
mejor_cp <- arbol$cptable[which.min(arbol$cptable[, "xerror"]), "CP"]
arbol_podado <- prune(arbol, cp = mejor_cp)

rpart.plot(arbol_podado,
           type = 4, extra = 101, box.palette = "Greens",
           main = "Árbol podado")

# Predecir sobre los mismos datos y guardarlo como columna nueva
base$pred <- predict(arbol_podado, base)
head(base)

# Métrica simple: error cuadrático medio (RMSE) entre real y predicho
rmse <- sqrt(mean((base$sales - base$pred)^2))
cat("RMSE:", round(rmse, 3), "\n")

# ============================================================
# Fin del TP
# ============================================================
