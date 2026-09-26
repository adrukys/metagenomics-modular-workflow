#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso    Este script lleva a cabo la anotación funcional con eggNOG-mapper a partir del conjunto
#        de genes predichos. Además cruza la información de anotación con la matriz de abundancias
#        de CoverM.
# Programas usados: eggNOG-mapper (v3, database v7), python3 y pandas (libreria de python3).

# Rutas de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
CDHIT="${WORKDIR}/13-cdhit"
COUNTS="${WORKDIR}/15-counts"
EGGNOG="${WORKDIR}/16-eggnog"

# Creación de directorios con resultados
mkdir -p "${EGGNOG}"

# Inicialización de conda
source $(conda info --base)/etc/profile.d/conda.sh

# =====================================
# MÓDULO 1: Anotación funcional
# =====================================

# Activación del entorno de conda
conda activate eggNOG-mapper

# eggNOG-mapper (Anotación funcional)
echo -e "\n---Iniciando anotación funcional---\n"

# -m: algoritmo; --cpu: hilos
emapper.py -i "${CDHIT}"/nr_proteins.faa \
           -o "${EGGNOG}"/functional_anotation \
           -m diamond \
           --cpu 12

echo -e "\n---Anotacion terminada---\n"

# =====================================
# MÓDULO 2: Perfil de abundancia funcional
# =====================================

# Eliminar comentarios y líneas innecesarias
# NOTA: la cabezera no se elimina
grep -v "##" "${EGGNOG}/functional_anotation.emapper.annotations" > "${EGGNOG}/clean_annotations.tsv"

python3 -c "
import pandas as pd

# Cargar datos
counts = pd.read_csv('${COUNTS}/gene_abundances.tsv', sep='\t')
annot = pd.read_csv('${EGGNOG}/clean_annotations.tsv', sep='\t', low_memory=False) # low_memory=False evita errores de formato

# Identificar columnas para el merge
col_counts = counts.columns[0]
col_annot = annot.columns[0]

# Left join y eliminación de columna duplicada
merged = pd.merge(counts, annot, left_on=col_counts, right_on=col_annot, how='left').drop(columns=[col_annot])

# Resultados
merged.to_csv('${EGGNOG}/gene_functional_abundance_profile.tsv', sep='\t', index=False)
"
conda deactivate

echo -e "\n---Matriz final generada, anotación funcional lista---\n"
