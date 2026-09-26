#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso:   Este script calcula la matriz de abundancias (conteos y tpm) a partir de
#        los BAMs generados en el mapeo de las lecturas curadas contra el catálogo
#        de genes (nucleótidos) predicho por metaProdigal y CD-HIT.
# Programas usados: CoverM (0.8.0)

# Rutas de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
MAPPING="${WORKDIR}/14-mapping_funtional"
COUNTS="${WORKDIR}/15-counts"

# Creación de directorios
mkdir -p "${COUNTS}"

# Inicialización de conda
source $(conda info --base)/etc/profile.d/conda.sh

# Activar entorno de conda
conda activate CoverM

# CoverM
echo -e "\n---Iniciando cálculo de abundancias---\n"

coverm contig \
    --bam-files "${MAPPING}"/*.bam \
    --methods count tpm \
    --output-file "${COUNTS}/gene_abundances.tsv" \
    --threads 20

conda deactivate
echo -e "\n---Cuantificación finalizada---\n"

