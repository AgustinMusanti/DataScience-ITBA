# Parte A - Preprocesamiento de los datos 

# Carga del dataset de granos de trigo 

base = read.table("seeds_dataset.txt", header = FALSE) 

head(base) 

# Renombrado de las variables según los atributos de los granos 

names(base)[names(base) == "V1"] = "Area" 
names(base)[names(base) == "V2"] = "Perimetro" 
names(base)[names(base) == "V3"] = "Compactitud" 
names(base)[names(base) == "V4"] = "Largo" 
names(base)[names(base) == "V5"] = "Ancho" 
names(base)[names(base) == "V6"] = "Asimetria" 
names(base)[names(base) == "V7"] = "Division" 
names(base)[names(base) == "V8"] = "Tipo" 

head(base) 

# Transformación de la variable Tipo a categórica 

base$Tipo = factor(base$Tipo, levels = c(1, 2, 3), labels = c("kama", "rosa", 
"canadian")) 

head(base) 

# Parte B - Análisis Exploratorio de Datos 

# Cantidad de semillas en total y por variedad 

dim(base)

summary(base$Tipo) 

# Gráfico de barras de la variable a predecir Tipo 

plot(base$Tipo, main = "Variedades de trigo") 

# Gráfico de dispersión entre Largo y Ancho, coloreado por Tipo 

library(caret) 

xyplot(Ancho ~ Largo, groups = Tipo, base, auto.key = TRUE, main = "Grafico 
de Agustin", pch = 19) 

# Registro correspondiente a los 2 últimos dígitos del DNI (05) 

trigo = base[05, ] 
trigo 

# Parte C - Conjuntos 

# Partición en entrenamiento (75%) y testeo (25%) 

# Semilla es mi DNI completo (XXXX5505). DNI termina en 5 por lo tanto p=0.75 

library(caret) 

set.seed(XXXX5505); particion = createDataPartition(y = base$Tipo, p = 0.75, 
list = FALSE) 

entreno = base[particion, ] 
testeo = base[-particion, ] 

# head y summary de cada conjunto 

head(entreno) 
summary(entreno) 

head(testeo) 
summary(testeo) 

# Cantidad de registros por variedad en cada conjunto 

summary(base$Tipo) 
summary(entreno$Tipo) 
summary(testeo$Tipo) 

# Parte D - Árbol de Decisión 

# Creación del Árbol de Decisión con la librería rpart 

library(rpart) 

arbol = rpart(Tipo ~ ., entreno) 

print(arbol) 

# Gráfico del Árbol de Decisión 

library(rpart.plot) 

rpart.plot(arbol, extra = 1, type = 5) 

# Matriz de confusión sobre el conjunto de testeo 

pred = predict(arbol, testeo, type = "class") 

confusionMatrix(pred, testeo$Tipo) 

# Verificación: aciertos (diagonal) sobre total de testeo = accuracy 

44/51 

# Predicción de la semilla correspondiente al DNI 

predict(arbol, trigo, type = "class") 

# Parte E - Red Neuronal 

# Creación de la Red Neuronal con la librería nnet 

# Como semilla se utiliza mi DNI completo 

library(nnet) 

set.seed(XXXX5505); red = nnet(Tipo ~ ., entreno, size = 25, maxit = 10000) 

# Información de la red 

print(red) 

# Gráfico de la Red Neuronal con colores personalizados 

library(NeuralNetTools) 

plotnet(red, 
        circle_col = "lightsteelblue",   # nodos / neuronas 
        pos_col    = "forestgreen",      
        neg_col    = "firebrick",  
        bord_col   = "gray40")           

# Matriz de confusión sobre el conjunto de testeo 

pred2 = predict(red, testeo, type = "class") 

confusionMatrix(factor(pred2), testeo$Tipo) 

# Predicción de la semilla correspondiente al DNI 

predict(red, trigo, type = "class")
