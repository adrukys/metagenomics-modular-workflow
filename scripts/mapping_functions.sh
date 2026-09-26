#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso:   Este script hace el mapeo de las lecturas curadas en pasos anteriores
#        contra las secuencias de nucleótidos codificantes de proteínas predichas
#        por metaProdigal y CD-HIT.
# Programas usados: BWA (0.7.19-r1273) y samtools (1.24)

# Rutas de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
CDHIT="${WORKDIR}/13-cdhit"
READS="${WORKDIR}/02-processed"
MAPPING="${WORKDIR}/14-mapping_funtional"

# Creación de directorios de salida
mkdir -p "${MAPPING}"

# Inicializar conda
source $(conda info --base)/etc/profile.d/conda.sh

# Activar entorno con bwa y samtools
conda activate mapping_bwa

# BWA y samtools

# a. Indexar archivo nr_genes.ffn
echo -e "\nIndexando las secuencias de nucleótidos\n"
bwa index "${CDHIT}/nr_genes.ffn"

# b. Mapeo y conversion a BAM (samtools)
for R1 in "${READS}"/*_clean_R1_001.fastq.gz; do
    # Extraer el prefijo (ej: MBW_S1_L001)
    PREFIX=$(basename "${R1}" _clean_R1_001.fastq.gz)
    R2="${READS}/${PREFIX}_clean_R2_001.fastq.gz"
    BAM_OUT="${MAPPING}/${PREFIX}.bam"

    echo -e "\nMapeando muestra: ${PREFIX}\n"

    # Mapeo con bwa, conversion a bam y ordenamiento
    bwa mem -t 20 "${CDHIT}/nr_genes.ffn" "${R1}" "${R2}" | \
    samtools view -@ 16 -b - | \
    samtools sort -@ 16 -o "${BAM_OUT}" -

    # Indexar el archivo BAM resultante
    echo -e "\nIndexando BAM: ${PREFIX}\n"
    samtools index -@ 16 "${BAM_OUT}"
done

conda deactivate
echo -e "\n---Mapeo finalizado---\n"


