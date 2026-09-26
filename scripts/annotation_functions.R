# Autor: Adrián Sánchez Maestro
# Uso:   Este script permite trabajar con archivos.tsv de anotación funcional
#        creando figuras como heatmaps.

# 0. Establecer entorno de trabajo
setwd("~/Documentos/bioinformatics/master/tfm/")

# 1. Cargar paquetes necesarios
library(tidyverse)
library(pheatmap)

# 2. Cargar datos
df <- read.delim("data/16-eggnog/genes_nitrogeno_final.tsv", header = TRUE, sep = "\t", check.names = FALSE)

# 3. Filtrar, agrupar y sumar TPMs por gen
df_tpm <- df %>%
  # Suponiendo que la columna del gen se llama "Preferred_name"
  select(Preferred_name, contains("TPM")) %>%
  # Filtramos para quedarnos solo con los genes clave que hemos detectado
  filter(Preferred_name %in% c("nifH", "nifD", "nifK", "napA", "napB", "narH", "narI", "nirK", "nirS", "norB", "norC", "nosZ")) %>%
  # Agrupar y sumar por si el gen está repetido en distintos contigs
  group_by(Preferred_name) %>%
  summarise_all(sum)

# 4. Convertir a matriz numérica para pheatmap
matriz <- as.matrix(df_tpm[, -1])
rownames(matriz) <- df_tpm$Preferred_name

# Limpiar los nombres de las columnas para el gráfico
colnames(matriz) <- c("MBW", "PTW", "SBW", "SC1")

pdf("documents/imagenes/figura_10/heatmap_nitrogen.pdf", width = 8, height = 6)
# 5. pheatmap
pheatmap(log1p(matriz),            # Se usa log1p para suavizar la escala visual
         cluster_cols = FALSE,     # No agrupar columnas para mantener el orden de muestras
         cluster_rows = TRUE,      # Agrupar genes con perfiles de expresión similares
         display_numbers = round(matriz, 1), # Mostrar el valor TPM original en las celdas
         color = colorRampPalette(c("white", "firebrick3"))(50), # Rampa de colores
         main = "Perfil funcional: Ciclo del Nitrógeno (log TPM)",
         fontsize = 12)
dev.off()
