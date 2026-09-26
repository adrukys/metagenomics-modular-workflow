#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso:   Este script es capaz de hacer un ensamblaje de novo con lecturas de Illumina curadas en modalidad
#        de co-ensamblaje usando la herrramienta MEGAHIT. El script incorpora el paso de análisis de calidad
#        usando metaQUAST.
# Programas usados: MEGAHIT (v1.2.9) y metaQUAST (v5.3.0)

# Inicialización de mamba (gestor de entornos y dependencias)
source "$(conda info --base)/etc/profile.d/conda.sh"

# Rutas de trabajo
reads_path="data/02-processed"
asm_path="data/04-assembly"
quast_path="data/05-quast_assembly/raw_contigs"

# Creacion de directorios
mkdir -p "$asm_path" "$quast_path"

# Comprobación de seguridad
archivos_r1=("$reads_path"/*_clean_R1_001.fastq.gz)
if [ ! -e "${archivos_r1[0]}" ]; then
    echo "Error: No se encontraron archivos procesados en $reads_path"
    exit 1
fi

# Variables de trabajo
r1_list=""
r2_list=""
pooled_r1="$reads_path/pooled_R1_001.fastq.gz"
pooled_r2="$reads_path/pooled_R2_001.fastq.gz"

# Limpiar archivos pooled por si se ha ejecutado el script previamente
> "$pooled_r1"
> "$pooled_r2"

# Crear listas (MEGAHIT) y concatenación (metaQUAST)
for r1 in "${archivos_r1[@]}"; do
    base=$(basename "$r1" _clean_R1_001.fastq.gz)
    r2="$reads_path/${base}_clean_R2_001.fastq.gz"

    # a) Construcción de las listas para MEGAHIT
    r1_list+="$r1,"
    r2_list+="$r2,"

    # b) Creación de fastq con todas las lecturas (pooling)
    cat "$r1" >> "$pooled_r1"
    cat "$r2" >> "$pooled_r2"
done

# Eliminar la última coma sobrante
r1_list=${r1_list%,}
r2_list=${r2_list%,}

# 1) MEGAHIT (assembly)
conda activate assembly_megahit # Inicialización entorno de mamba
megahit -1 "$r1_list" \
        -2 "$r2_list" \
        -o "$asm_path" \
        -t 20 \
        -f # MEGAHIT da error si la carpeta de salida ya existe

# 2) metaQUAST (assembly quality control)
conda activate quality_control_assembly # Inicialización entorno de mamba
metaquast.py "$asm_path/final.contigs.fa" \
    --pe1 "$pooled_r1" \
    --pe2 "$pooled_r2" \
    --max-ref-number 0 \
    -t 20 \
    -o "$quast_path"

# Desactivar mamba
conda deactivate
