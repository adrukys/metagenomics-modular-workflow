#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso:   Este script es capaz de llevar a cabo los pasos de refinado y postprocesado
#        de los bins, incluyendo el uso de herramientas como DAStool, CheckM2, dRep
#        y metaQUAST.
# Programas usados: DAStool (v1.1.7), CheckM2 (v1.1.0) y dRep (v3.7.1)

# Rutas de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
CONTIG="${WORKDIR}/04-assembly/final.contigs.filtered.fa"
BINNING="${WORKDIR}/07-binning"

# Directorios con los resultados
DASTOOL="${WORKDIR}/08-dastool"
CHECKM2="${WORKDIR}/09-checkm2"
DREP="${WORKDIR}/10-drep"
QUAST="${WORKDIR}/11-quast_binning"

# Creación de directorios
mkdir -p "${DASTOOL}" "${CHECKM2}" "${DREP}" "${QUAST}"

# Activación de conda
source $(conda info --base)/etc/profile.d/conda.sh

# ==========================================
# MÓDULO 1: DAStool
# ==========================================

echo -e "\n--- Iniciando DAS Tool ---\n"
conda activate DAStool

# a. Generación de archivos.tsv para DAStool
# NOTA: DAStool incorpora algunos scripts que funcionan bien, como el de CONCOCT y Maxbin, pero otros como el de MetaBat2 no funciona bien.
# 1. CONCOCT
# Eliminamos las primeras dos lineas del archivo de concoct (clustering_merged.csv) porque si no da error y ya ejecutamos el script
grep -v "contig_id" "${BINNING}/concoct/clustering_merged.csv" > "${BINNING}/concoct/clustering_merged_clean.csv"
perl -pe "s/,/\tconcoct./g;" "${BINNING}/concoct/clustering_merged_clean.csv" > "${DASTOOL}/concoct.tsv" # Script oficial

# 2. MAXBIN2
Fasta_to_Contig2Bin.sh -i "${BINNING}/maxbin2" -e fasta > "${DASTOOL}/maxbin2.tsv" # Script oficial

# 3. METABAT2
> "${DASTOOL}/metabat2.tsv" # Crea o elimina el archivo

for bin in "${BINNING}/metabat2"/*.fa; do
    # Si existe el archivo
    [ -e "$bin" ] || continue
    # Extraer el nombre del bin
    bin_name=$(basename "$bin" .fa)
    # Busca lineas con ">" y las extrae, sed elimina ">" y awk lo imprime
    grep "^>" "$bin" | sed 's/>//g' | awk -v b="$bin_name" '{print $1 "\t" b}' >> "${DASTOOL}/metabat2.tsv"
done

# b. Ejecucion de DAStool
DAS_Tool -i "${DASTOOL}/concoct.tsv,${DASTOOL}/maxbin2.tsv,${DASTOOL}/metabat2.tsv" \
         -l concoct,maxbin2,metabat2 \
         -c "${CONTIG}" \
         -o "${DASTOOL}/dastool" \
         -t 16 \
         --write_bin_evals --write_bins

echo -e "\n--- DAS Tool finalizado ---\n"
conda deactivate

# ==========================================
# MÓDULO 2: CheckM2
# ==========================================

echo -e "\n--- Iniciando CheckM2 ---\n"
conda activate checkm2

# CheckM2 evalúa la completitud y contaminación de los bins seleccionados por DAS Tool
checkm2 predict --threads 16 \
                --input "${DASTOOL}/dastool_DASTool_bins" \
                --output-directory "${CHECKM2}" \
                -x fa
                #--database_path "${WORKDIR}/00-databases/checkm2_database/"

# Conexión de CheckM2 con dRep
awk 'BEGIN{FS="\t"; OFS=","} NR==1{print "genome","completeness","contamination"} NR>1{print $1".fa",$2,$3}' "${CHECKM2}/quality_report.tsv" > "${CHECKM2}/genomeInfo.csv"

conda deactivate
echo -e "\n--- CheckM2 finalizado ---\n"

# ==========================================
# MÓDULO 3: dRep
# ==========================================

echo -e "\n--- Iniciando dRep ---\n"
conda activate drep

# dRep agrupa bins similares (>99% ANI por defecto) y elegirá el mejor representante
# Filtro: completitud > 50%, contaminación < 10%
dRep dereplicate "${DREP}" \
                 -g "${DASTOOL}/dastool_DASTool_bins"/*.fa \
                 -p 16 \
                 --completeness 50 --contamination 10 \
                 --genomeInfo "${CHECKM2}/genomeInfo.csv"

conda deactivate
echo -e "\n--- dRep finalizado ---\n"

# ==========================================
# MÓDULO 4: metaQUAST
# ==========================================

echo -e "\n--- Iniciando metaQUAST ---\n"
conda activate quality_control_assembly

# Evaluar únicamente los mejores MAGs
metaquast.py "${DREP}/dereplicated_genomes"/*.fa \
             -o "${QUAST}" \
             -t 16 \
             --max-ref-number 0

conda deactivate
echo -e "\n--- metaQUAST finalizado ---\n"
