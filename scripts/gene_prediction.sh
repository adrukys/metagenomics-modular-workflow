#!/usr/bin/env bash

# Autor: Adrián Sánchez Maestro
# Uso    Este script es capaz de predecir genes a partir de MAGs obtenidos en pasos
#        de binning anteriores. Se obtienen las secuencias proteícas así como las
#        nucleotídicas correspondientes.
# Programas usados: Prodigal (v2.6.3) y CD-HIT (v4.8.1)

# Rutas de trabajo
WORKDIR="${HOME}/Documentos/bioinformatics/master/tfm/data"
MAGS="${WORKDIR}/10-drep/dereplicated_genomes"
PRODIGAL="${WORKDIR}/12-prodigal"
CDHIT="${WORKDIR}/13-cdhit"

# Creación de directorios
mkdir -p "${PRODIGAL}" "${CDHIT}"

# Inicialización de conda
source $(conda info --base)/etc/profile.d/conda.sh

# ==========================================
# MÓDULO 1: metaProdigal
# ==========================================

# Activación del entorno de conda
echo -e "\n---Inicialización de prodigal---\n"
conda activate prodigal

# Procesamiento de cada MAG de forma iterativa
for mag in "${MAGS}"/*.fa; do
    filename=$(basename -- "$mag")
    base="${filename%.*}" # Formato .fa o .fasta

    echo -e "\nProcesando $base\n"

    # -a: archivo de proteínas, -d: archivo de nucleótidos, -o: anotaciones, -f: formato
    prodigal -i "$mag" \
        -a "${PRODIGAL}/${base}.faa" \
        -d "${PRODIGAL}/${base}.ffn" \
        -o "${PRODIGAL}/${base}.gff" \
        -f gff \
        -q # Modo silencioso
done

# Concatenacion de todos los resultados
# Proteínas
cat "${PRODIGAL}"/*.faa > "${PRODIGAL}"/proteins.faa
# Nucleótidos
cat "${PRODIGAL}"/*.ffn > "${PRODIGAL}"/genes.ffn

echo -e "\n---Prodigal finalizado---\n"
conda deactivate

# ==========================================
# MÓDULO 2: CD-HIT
# ==========================================

echo -e "\n---Inicialización de CD-HIT\n"
conda activate CD-HIT

# CD-HIT
# i: input, o: output, c: identidad, n: longitud de palabra, M: RAM, T: hilos
cd-hit -i "${PRODIGAL}/proteins.faa" \
       -o "${CDHIT}/nr_proteins.faa" \
       -c 0.95 \
       -n 5 \
       -M 60000 \
       -T 20

cd-hit-est -i "${PRODIGAL}/genes.ffn" \
       -o "${CDHIT}/nr_genes.ffn" \
       -c 0.95 \
       -n 10 \
       -M 60000 \
       -T 20

conda deactivate
echo -e "\n---CD-HIT finalizado---\n"
