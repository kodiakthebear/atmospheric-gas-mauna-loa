# Atmospheric Gas Concentration Analysis — Mauna Loa Observatory

![R](https://img.shields.io/badge/R-4.x-276DC3?style=flat&logo=r&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=flat)
![Status](https://img.shields.io/badge/status-complete-brightgreen?style=flat)
![Domain](https://img.shields.io/badge/domain-Environmental%20Data%20Science-2e7d32?style=flat)
![Methods](https://img.shields.io/badge/methods-PCA%20%7C%20K--Means%20%7C%20K--Medoids%20%7C%20MICE-blue?style=flat)

An end-to-end unsupervised learning analysis of 20 years of atmospheric gas concentration data collected at the Mauna Loa volcanic observatory (2000–2019). The project covers exploratory data analysis, missing value imputation, dimensionality reduction via PCA, and cluster analysis using K-Means and K-Medoids, with a Gaussian Mixture Model explored as an alternative.

---

## Table of Contents

- [Overview](#overview)
- [Dataset](#dataset)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Analysis Pipeline](#analysis-pipeline)
  - [1. Exploratory Data Analysis](#1-exploratory-data-analysis)
  - [2. Missing Value Imputation](#2-missing-value-imputation)
  - [3. Dimensionality Reduction (PCA)](#3-dimensionality-reduction-pca)
  - [4. Cluster Analysis](#4-cluster-analysis)
- [Key Findings](#key-findings)
- [How to Run](#how-to-run)
- [Dependencies](#dependencies)

---

## Overview

This project applies a full unsupervised learning pipeline to monthly atmospheric gas concentration readings from the Mauna Loa Observatory. The goal is to uncover hidden structure in the data — identifying variable relationships, reducing dimensionality, and grouping observations into meaningful clusters — without relying on labelled outcomes.

All analytical choices (imputation method, number of PCs retained, clustering algorithm, value of K) are made based on statistical evidence and interpreted in context.

---

## Dataset

| Property | Detail |
|---|---|
| **Source** | Mauna Loa Volcanic Observatory |
| **Period** | 2000 – 2019 |
| **Observations** | 186 monthly readings |
| **Variables** | Date, CO (ppb), CO₂ (ppm), Methane/CH₄ (ppb), Nitrous Oxide/N₂O (ppb), CFC-11 (ppt) |
| **Missing Data** | ~18% induced missingness across CO and CO₂ |

> **Note:** The dataset (`MaunaLoa_miss.csv`) is included in this repository.

---

## Tech Stack

| Category | Tools |
|---|---|
| **Language** | R |
| **Data Manipulation** | `tidyr`, `reshape2` |
| **Visualisation** | `ggplot2`, `ggcorrplot`, `GGally`, `beeswarm`, `plotly`, `factoextra` |
| **Missing Data** | `naniar`, `VIM`, `mice` |
| **Dimensionality Reduction** | `stats::prcomp`, `factoextra` |
| **Clustering** | `stats::kmeans`, `cluster::clara` (K-Medoids), `mclust` (GMM) |
| **Cluster Validation** | WSS, Silhouette Score, BIC |

---

## Project Structure

```
mauna-loa-analysis/
│
├── MaunaLoa_miss.csv        # Raw dataset with induced missing values
├── analysis.R               # Full analysis script (EDA → PCA → Clustering)
├── README.md                # Project documentation
└── plots/                   # Output visualisations (optional)
```

---

## Analysis Pipeline

### 1. Exploratory Data Analysis

- Inspected variable types, distributions, and summary statistics
- Generated boxplots to identify outliers across all five gas variables
- Produced histogram and scatterplot matrices to study distributions and inter-variable relationships
- Constructed a correlation heatmap, revealing moderate-to-high correlations between variables (e.g. CO₂ & N₂O: r = 0.94), indicating redundancy and motivating dimensionality reduction
- Plotted time series of all gas concentrations to observe temporal trends across the 20-year period

### 2. Missing Value Imputation

- Diagnosed missingness pattern using `naniar::vis_miss` and `VIM::aggr`
- Identified CO (11% missing) and CO₂ (8% missing) as the affected variables
- Concluded missingness was **Missing At Random (MAR)** — values were absent for specific date ranges and linked to observed variables, not to the missing values themselves
- Applied **MICE** (`method = "norm.predict"`, `seed = 123`) to impute missing values
- Verified post-imputation that distributions remained unchanged using the same diagnostic plots

### 3. Dimensionality Reduction (PCA)

- Scaled all five gas variables to zero mean and unit variance using `scale()` prior to PCA
- Applied `prcomp()` to the scaled dataset
- **PC1 and PC2 retained**, collectively explaining **80.42% of total variance** (PC1: 61.3%, PC2: 19.1%), exceeding the standard 80% retention threshold
- Interpreted principal components via variable loadings and contribution plots:
  - **PC1** — dominated by N₂O, CO₂, and CFC-11; captures general atmospheric concentration levels, potentially linked to volcanic eruption events
  - **PC2** — driven by CO, CFC-11, and CH₄; distinguishes carbon-based greenhouse gases independently of eruption-scale effects

### 4. Cluster Analysis

Clustering was performed on the PCA-reduced dataset (PC1 + PC2).

#### K-Means Clustering
- Determined optimal K using WSS (elbow method) and Silhouette score — methods suggested K=4 and K=2 respectively
- Evaluated both visually; **K=4 selected** for greater granularity and interpretability
- Clusters 3 and 4 formed the dense central body of observations; clusters 1 and 2 captured outlying points
- Cluster centroids visibly distorted by outliers due to K-Means' sensitivity to extreme values

#### K-Medoids Clustering (PAM via CLARA)
- Silhouette analysis recommended **K=9**
- Produced a more granular structure: 3 clusters capturing outliers, 6 forming the central body
- Cluster centres remained stable in the presence of outliers — demonstrating K-Medoids' robustness over K-Means via the PAM (Partitioning Around Medoids) algorithm
- Notably, outlier datapoint 134 severely distorted K-Means confidence intervals but had no such effect on K-Medoids

#### Gaussian Mixture Model (GMM) — Exploratory
- BIC-based model selection applied across G = 1–10 components
- EVI model with G=6 components explored; classification, uncertainty, density, and BIC plots generated

---

## Key Findings

- **Variable correlations are high** — particularly between CO₂ and N₂O (r = 0.94), justifying PCA-based dimensionality reduction
- **Two principal components suffice** to represent 80.42% of dataset variance, cleanly separating eruption-linked gases from carbon-based greenhouse gases
- **K-Medoids outperforms K-Means** in this dataset due to the presence of outliers; PAM-based centres are more representative of true cluster structure
- **Temporal patterns remain unexplored** — incorporating the Date variable into the clustering framework could reveal how atmospheric gas compositions shifted over the 20-year period, a promising direction for future analysis

---

## How to Run

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mauna-loa-analysis.git
   cd mauna-loa-analysis
   ```

2. Open `analysis.R` in RStudio or your preferred R environment.

3. Update the data path on line 24 to point to your local copy of `MaunaLoa_miss.csv`:
   ```r
   MLoa <- read.csv("MaunaLoa_miss.csv")
   ```

4. Install required packages (see below) and run the script section by section.

---

## Dependencies

Install all required packages in R:

```r
install.packages(c(
  "naniar", "reshape2", "beeswarm", "mice", "VIM",
  "plotly", "ggplot2", "corrplot", "GGally", "ggcorrplot",
  "tidyr", "factoextra", "NbClust", "cluster", "mclust"
))
```

---

*Project completed as part of the MSc Data Science programme at Durham University (2024–2025).*
