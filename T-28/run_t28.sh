#!/bin/bash
# T-28: Script de ejecución de pruebas RPA en ambos CRM
# Autor: Luis Vásquez
# Fecha: 15 de octubre de 2026

echo "=========================================="
echo "T-28: Pruebas RPA en ambos CRM"
echo "=========================================="
echo ""

mkdir -p resultados/ubuntu
mkdir -p resultados/windows

echo "[1/2] Ejecutando guion para VM-01 (Ubuntu)..."
robot --outputdir resultados/ubuntu guion_rpa_ubuntu.robot
echo ""

echo "[2/2] Ejecutando guion para VM-02 (Windows)..."
robot --outputdir resultados/windows guion_rpa_windows.robot
echo ""

echo "=========================================="
echo "Pruebas finalizadas"
echo "Reportes disponibles en:"
echo "  - resultados/ubuntu/report.html"
echo "  - resultados/windows/report.html"
echo "=========================================="
