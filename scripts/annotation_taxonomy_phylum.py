# Autor: Adrián Sánchez Maestro
# Uso:   Este script permite graficar el perfil taxonómico (a nivel de Filo (Phylum))
#        a partir de la tabla de taxonomia refinada, obtenida de gtdbtk en pasos
#        anteriores.

# ===================================
# a. Cargar librerias
# ===================================
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# ===================================
# b. Directorios de trabajo y archivo de taxonomia
# ===================================
workdir = "/home/adruky/Documentos/bioinformatics/master/tfm"
results = f"{workdir}/results"
taxonomy = f"{results}/tabla_taxonomia.tsv"

df_taxonomy = pd.read_csv(taxonomy, sep='\t')

# ===================================
# c. Conteos por Phylum y Dominio
# ===================================

# Conteo de cuantos MAGs hay
conteo_phylum = df_taxonomy.groupby(['Domain', 'Phylum']).size().reset_index(name='Count')
# Ordenar de mayor a menor para que el gráfico quede escalonado
conteo_phylum = conteo_phylum.sort_values('Count', ascending=False)

# ===================================
# d. Gráfica
# ===================================
plt.figure(figsize=(10, 6))

# Paleta de colores
colores = {'Archaea': '#E66100', 'Bacteria': '#5D3A9B'}

ax = sns.barplot(
    data=conteo_phylum,
    x='Count',
    y='Phylum',
    hue='Domain',
    palette=colores,
    dodge=False
)

plt.title('Diversidad taxónomica de los MAGs recuperados (Filo)', fontsize=14, pad=15)
plt.xlabel('Número de MAGs', fontsize=12)
plt.ylabel('Phylum', fontsize=12)

# Añadir el número exacto al final de cada barra
for i in ax.containers:
    ax.bar_label(i, padding=5, fontsize=10)
plt.tight_layout()

# ===================================
# f. Guardado de la figura
# ===================================
output_svg = f"{results}/barplot_taxonomia_phylum.svg"
plt.savefig(output_svg, format='svg', transparent=True)
print(f"Grafico guardado: en {output_svg}")
plt.show()
