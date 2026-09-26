# Autor: Adrián Sánchez Maestro
# Uso:   Este script permite graficar el perfil taxonómico (a nivel de Familia (Family))
#        a partir de la tabla de taxonomia refinada, obtenida de gtdbtk en pasos anteriores.

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

# Ajuste para rellenar huecos vacios
df_taxonomy.fillna('Unclassified', inplace=True)

# ===================================
# c. Conteos por Phylum y Dominio
# ===================================

# Conteo de cuantos MAGs hay
conteo_family = df_taxonomy.groupby(['Phylum', 'Family']).size().reset_index(name='Count')
# Ordenar de mayor a menor para que el gráfico quede escalonado
conteo_family = conteo_family.sort_values(by=['Phylum', 'Count'], ascending=[True, False])

# ===================================
# d. Gráfica
# ===================================
plt.figure(figsize=(12, 10))

# Paleta de colores (según el número de Phylum únicos)
phyla_unicos = conteo_family['Phylum'].unique()
colores = dict(zip(phyla_unicos, sns.color_palette("tab20", len(phyla_unicos))))

ax = sns.barplot(
    data=conteo_family,
    x='Count',
    y='Family',
    hue='Phylum',
    palette=colores,
    dodge=False
)

plt.title('Diversidad taxónomica de los MAGs recuperados (Familia)', fontsize=16, pad=15)
plt.xlabel('Número de MAGs', fontsize=12)
plt.ylabel('Familia', fontsize=12)

# Añadir el número exacto al final de cada barra
for i in ax.containers:
    ax.bar_label(i, padding=5, fontsize=10)

# Ajuste de la leyenda para que no interceda con el gráfico
plt.legend(title='Phylum', bbox_to_anchor=(1.05, 1), loc='upper left')
plt.tight_layout()

# ===================================
# f. Guardado de la figura
# ===================================
output_svg = f"{results}/barplot_taxonomia_family.svg"
plt.savefig(output_svg, format='svg', transparent=True, bbox_inches='tight')
print(f"Grafico guardado: en {output_svg}")
plt.show()
