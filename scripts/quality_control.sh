#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso: Este script lleva a cabo el preprocesado de las lecturas crudas procedentes de Illumina.

# Rutas de trabajo
workdir="${HOME}/Documentos/bioinformatics/master/tfm/data"
reads_path="${workdir}/01-raw"
out_path="${workdir}/02-processed"
qc_path="${workdir}/03-quality_control/fastp_processed"

# Crear directorios de trabajo
mkdir -p "$out_path" "$qc_path"

# Comprobación de seguridad
archivos_r1=("$reads_path"/*_R1_001.fastq.gz)
if [ ! -e "${archivos_r1[0]}" ]; then
    echo "Error: No se encontraron archivos fastq.gz en $reads_path"
    exit 1
fi

for r1 in "${archivos_r1[@]}"; do
    # Extrae el nombre de la muestra
    base=$(basename "$r1" _R1_001.fastq.gz)
    r2="$reads_path/${base}_R2_001.fastq.gz"

    out_R1="$out_path/${base}_clean_R1_001.fastq.gz"
    out_R2="$out_path/${base}_clean_R2_001.fastq.gz"

    echo -e "\nIniciando preprocesado de la muestra: $base\n"

    # Preprocesado con fastp
    fastp -i "$r1" -I "$r2" -o "$out_R1" -O "$out_R2" \
        --cut_front --cut_tail --cut_mean_quality 20 \
        --trim_poly_g --detect_adapter_for_pe -l 40 \
        -w 8 \
        -h "$qc_path/${base}_report.html" -j "$qc_path/${base}_report.json"
done

echo "Análisis de calidad completado para todas las muestras."

