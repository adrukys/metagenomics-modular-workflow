#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso:   Este script esta preparado para hacer el binning usando tres algortimos distintos (CONCOCT, MetaBat2, Maxbin2)
#        a partir de un ensamblaje metagenómico realizado en pasos anteriores.
# Programas usados: MaxBin (v2.2.7), CONCOCT (v1.1.0) y MetaBat2 (v2.2.18)

# Directorios de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
CONTIGS="${WORKDIR}/04-assembly/final.contigs.filtered.fa"
BAM="${WORKDIR}/06-mapping"
BINNING="${WORKDIR}/07-binning"

# Directorios de binning
CONCOCT="${BINNING}/concoct"
MAXBIN="${BINNING}/maxbin2"
METABAT="${BINNING}/metabat2"

# Creación de directorio de trabajo
mkdir -p "${BAM}" "${CONCOCT}" "${MAXBIN}" "${METABAT}"

# ==========================================
# MÓDULO 1: CONCOCT
# ==========================================
echo -e "\n--- Iniciando CONCOCT ---\n"

# a. Activar entorno de MAMBA
source $(conda info --base)/etc/profile.d/conda.sh
conda activate binning_concoct

# b. Trocear contigs
cut_up_fasta.py "${CONTIGS}" -c 10000 -o 0 --merge_last -b "${CONCOCT}/contigs_10K.bed" > "${CONCOCT}/contigs_10K.fa"

# c. Generar tabla de cobertura a partir de los BAM
concoct_coverage_table.py "${CONCOCT}/contigs_10K.bed" "${BAM}"/*.bam > "${CONCOCT}/coverage_table.tsv"

# d. Ejecutar CONCOCT
concoct --composition_file "${CONCOCT}/contigs_10K.fa" --coverage_file "${CONCOCT}/coverage_table.tsv" -b "${CONCOCT}/" -t 16

# e. Fusionar los clusters de nuevo a los contigs originales
merge_cutup_clustering.py "${CONCOCT}/clustering_gt1000.csv" > "${CONCOCT}/clustering_merged.csv"

# f. Extraer los bins a archivos FASTA
mkdir -p "${CONCOCT}/bins"
extract_fasta_bins.py "${CONTIGS}" "${CONCOCT}/clustering_merged.csv" --output_path "${CONCOCT}/bins/"

conda deactivate
echo -e "\n--- CONCOCT finalizado ---\n"

# ==========================================
# MÓDULO 2: MaxBin2
# ==========================================
echo -e "\n--- Iniciando MaxBin2 ---\n"

# a. Activar entorno de MAMBA
conda activate binning_maxbin2

# b. Generar archivos de abundancia por muestra y listarlos
> "${MAXBIN}/abund_list.txt"

for bam_file in "${BAM}"/*.bam; do
    base_name=$(basename "${bam_file}" .bam)
    abund_file="${MAXBIN}/${base_name}.abund"

    echo "Calculando abundancia para ${base_name}..."
    # samtools coverage extrae la profundidad media (columna 7) de cada contig
    samtools coverage "${bam_file}" | awk 'NR>1 {print $1 "\t" $7}' > "${abund_file}"

    echo "${abund_file}" >> "${MAXBIN}/abund_list.txt"
done

# c. Ejecutar MaxBin2
run_MaxBin.pl -contig "${CONTIGS}" -out "${MAXBIN}/mb2" -abund_list "${MAXBIN}/abund_list.txt" -thread 16

conda deactivate
echo -e "\n--- MaxBin2 finalizado ---\n"

# ==========================================
# MÓDULO 3: MetaBAT2
# ==========================================

echo -e "\n--- Iniciando MetaBAT2 ---\n"

# a. Activar entorno de MAMBA
conda activate binning_metabat2

# b. Generar archivo de profundidad a partir de todos los BAM
jgi_summarize_bam_contig_depths --outputDepth "${METABAT}/depth.txt" "${BAM}"/*.bam

# c. Ejecutar MetaBAT2
metabat2 -i "${CONTIGS}" -a "${METABAT}/depth.txt" -o "${METABAT}/bin" -m 1500 -t 16

conda deactivate
echo -e "\n--- MetaBAT2 finalizado ---\n"
