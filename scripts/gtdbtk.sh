#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso:   Este script clasifica la taxonomia de los MAGs obtenidos durante pasos anteriores.
# Programas usados: gtdb-tk (v2.1.1)

# Rutas de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
BINS="${WORKDIR}/10-drep/dereplicated_genomes"
GTDBTK="${WORKDIR}/17-gtdbtk"
SCRATCH="${GTDBTK}/scratch"

# Creación de directorios de salida
mkdir -p "${GTDBTK}" "${SCRATCH}"

# Definición de la ruta a la base de datos gtdbtk_r207
export GTDBTK_DATA_PATH="${WORKDIR}/00-databases/gtdbtk_database/release_207_v2"

# Inicialización de conda
source $(conda info --base)/etc/profile.d/conda.sh

# Activación del entorno de conda
conda activate gtdbtk_r207

# GTDB-TK
echo -e "\n---Iniciando clasificación taxonómica---\n"

# Uso: Classify_wf; con restricciones a pplacer (cpus=1)
gtdbtk classify_wf \
       --genome_dir "${BINS}" \
       --extension fa \
       --out_dir "${GTDBTK}" \
       --cpus 16 \
       --pplacer_cpus 1 \
       --scratch_dir "${SCRATCH}"

conda deactivate
echo -e "\n---Clasificación taxonómica finalizada---\n"

