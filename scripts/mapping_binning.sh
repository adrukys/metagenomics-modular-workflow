#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso:   Este script hace un mapeo de las lecturas curadas contra los contigs obtenidos
#        a partir de un ensamblaje con MEGAHIT.
# Programas usados: BWA (0.7.19-r1273) y samtools (1.24)

# Directorios de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
READS="${WORKDIR}/02-processed"
CONTIGS="${WORKDIR}/04-assembly/final.contigs.filtered.fa"
MAPPING="${WORKDIR}/06-mapping"

mkdir -p "${MAPPING}"

# Inicializar conda
source $(conda info --base)/etc/profile.d/conda.sh

# Activar entorno (bwa y samtools)
conda activate mapping_bwa

echo "--- Indexando referencia ---"
bwa index "${CONTIGS}"

echo -e "\n--- Iniciando mapeo con BWA ---"

# Bucle para procesar los pares de lecturas
for R1 in "${READS}"/*_clean_R1_001.fastq.gz; do
    # Extraer el prefijo (ej: MBW_S1_L001)
    PREFIX=$(basename "${R1}" _clean_R1_001.fastq.gz)
    R2="${READS}/${PREFIX}_clean_R2_001.fastq.gz"
    BAM_OUT="${MAPPING}/${PREFIX}.bam"

    echo "Mapeando muestra: ${PREFIX}..."

    # Mapeo con bwa, conversion a bam y ordenamiento
    bwa mem -t 16 "${CONTIGS}" "${R1}" "${R2}" | \
    samtools view -@ 8 -b - | \
    samtools sort -@ 8 -o "${BAM_OUT}" -

    # Indexar el archivo BAM resultante
    samtools index -@ 8 "${BAM_OUT}"
done

conda deactivate
echo -e "\n--- Mapeo finalizado ---"
