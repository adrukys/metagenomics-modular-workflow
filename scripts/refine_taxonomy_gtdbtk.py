# Autor: Adrián Sánchez Maestro
# Uso:   Este script es capaz de parsear las tablas de taxonomia obtenidas por gtdbk y
#        además las integra dando lugar a una sola tabla de taxonomia para crear figuras
#        y presentarla como resultado.

import pandas as pd
import os
import sys

# ===================================
# a. Rutas de los archivos
# ===================================
workdir="/home/adruky/Documentos/bioinformatics/master/tfm"
gtdbtk=f"{workdir}/data/18-gtdbtk"
results=f"{workdir}/results"

# ===================================
# b. Parseo del archivo de taxonomía
# ===================================
print("\nLimpiando archivo de taxonomia")

# Lista con las bacterias y arqueas
df = []
bac_file = os.path.join(gtdbtk, "gtdbtk.bac120.summary.tsv")
arq_file = os.path.join(gtdbtk, "gtdbtk.ar53.summary.tsv")

# Si existe añadimos el elemento a la lista df
if os.path.exists(bac_file):
    df.append(pd.read_csv(bac_file, sep='\t'))
if os.path.exists(arq_file):
    df.append(pd.read_csv(arq_file, sep='\t'))
df_tax = pd.concat(df, ignore_index=True)[['user_genome', 'classification']]

# Definición de los niveles taxonómicos
niveles = ['Domain', 'Phylum', 'Class', 'Order', 'Family', 'Genus', 'Species']
tax_split = df_tax['classification'].str.split(';', expand=True)

for col in tax_split.columns:
    tax_split[col] = tax_split[col].str.replace(r'^[a-z]__', '', regex=True)
tax_split.columns = niveles

df_tax_clean = pd.concat([df_tax[['user_genome']], tax_split], axis=1)

# Se renombra 'user_genome' a 'Bin'
df_tax_clean.rename(columns={'user_genome': 'Bin'}, inplace=True)

# Asignación de Unclassified a aquellas entidades taxonomicas que no hayan sido aginadas
df_tax_clean.fillna('Unclassified', inplace=True)

# ===================================
# c. Guardado de resultados
# ===================================
os.makedirs(results, exist_ok=True) # Asegura que el directorio exista
output_file = f"{results}/tabla_taxonomia.tsv"

df_tax_clean.to_csv(output_file, sep='\t', index=False)
print(f"Archivo guardado exitosamente en: {output_file}")
