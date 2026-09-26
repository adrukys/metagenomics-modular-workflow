# Autor: Adrián Sánchez Maestro
# Uso:   Este script es capaz de parsear las tablas de taxonomia obtenidas por gtdbk, además de la
#        tabla con las funciones, integrando toda la información en una única tabla maestra.

import pandas as pd
import os
from Bio import SeqIO

# ===================================
# a. Rutas de los archivos
# ===================================
workdir="/home/adruky/Documentos/bioinformatics/master/tfm"
gtdbtk=f"{workdir}/data/17-gtdbtk"
bins=f"{workdir}/data/10-drep/dereplicated_genomes"
functions=f"{workdir}/data/16-eggnog/gene_functional_abundance_profile.tsv"
results=f"{workdir}/results"

# ===================================
# b. Diccionario: CONTIG -> BIN
# ===================================
contig_to_bin = {}

# Bucle para recorrer todos los archivos.fa o .fasta (bins)
for filename in os.listdir(bins):
    if filename.endswith(".fa") or filename.endswith(".fasta"):
        bin_id = os.path.splitext(filename)[0]
        filepath = os.path.join(bins, filename)

        # Leer fasta y extraer los nombres de los contigs
        for record in SeqIO.parse(filepath, "fasta"):
            contig_id = record.id
            contig_to_bin[contig_id] = bin_id

print(f"Se han encontrado {len(contig_to_bin)} contigs con {len(set(contig_to_bin.values()))} bins.")

# ===================================
# c. Parseo del archivo de taxonomía
# ===================================
print("\nLimpiando archivo de taxonomia")

# Lista con las bacterias y arqueas
df = []
bac_file = os.path.join(gtdbtk, "gtdbtk.bac120.summary.tsv")
arq_file = os.path.join(gtdbtk, "gtdbtk.ar53.summary.tsv")

# Si existe añadimos el elemento a la lista df
if os.path.exists(bac_file): df.append(pd.read_csv(bac_file, sep='\t'))
if os.path.exists(arq_file): df.append(pd.read_csv(arq_file, sep='\t'))
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

# ===================================
# d. Cruce de la tabla funcional y tabla de taxonomia
# ===================================
print(f"\nCruce de tabla de taxonomía y funcional")

# Leer la tabla con las funciones
df_func = pd.read_csv(functions, sep='\t')

# Extracción del ID del contig a partir de l ID del gen
# 'K141_78198_1' -> 'K141_78198'
df_func['Contig_ID'] = df_func['Contig'].str.rsplit('_', n=1).str[0]

# Asignar el bin buscando el Contig_ID en el diccionario
df_func['Bin'] = df_func['Contig_ID'].map(contig_to_bin)

# Cruce de la tabla de taxonomia con la funcional usando la columna 'bin'
df_master = pd.merge(df_func, df_tax_clean, on='Bin', how='left')

# Borrado de la columna temporal 'Contig_ID'
df_master.drop(columns=['Contig_ID'], inplace=True)

# Guardado de la tabla final
output_file = f"{results}/tabla_maestra.tsv"
df_master.to_csv(output_file, sep='\t', index=False)
