#!/bin/bash
# ============================================================
# setup_lab.sh — Verificação do ambiente de laboratório
# Projeto: Brute Force com Medusa e Kali Linux (DIO)
# Uso: bash setup_lab.sh <IP_ALVO>
# ============================================================

TARGET=${1:-"192.168.56.102"}
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=============================================="
echo "  🔐 Lab Checker — Brute Force com Medusa"
echo "  Alvo: $TARGET"
echo "=============================================="

# 1. Verificar ferramentas instaladas
echo -e "\n${YELLOW}[*] Verificando ferramentas...${NC}"
for tool in medusa hydra nmap enum4linux smbclient; do
  if command -v $tool &>/dev/null; then
    echo -e "  ${GREEN}[✓]${NC} $tool instalado"
  else
    echo -e "  ${RED}[✗]${NC} $tool NÃO encontrado"
  fi
done

# 2. Testar conectividade com o alvo
echo -e "\n${YELLOW}[*] Testando conectividade com $TARGET...${NC}"
if ping -c 2 -W 2 "$TARGET" &>/dev/null; then
  echo -e "  ${GREEN}[✓]${NC} Alvo acessível"
else
  echo -e "  ${RED}[✗]${NC} Alvo inacessível — verifique a rede host-only"
  exit 1
fi

# 3. Scan de portas relevantes
echo -e "\n${YELLOW}[*] Escaneando portas (21, 22, 80, 139, 445)...${NC}"
nmap -sV -p 21,22,80,139,445 "$TARGET" 2>/dev/null | grep -E "open|closed|filtered"

# 4. Verificar wordlists
echo -e "\n${YELLOW}[*] Verificando wordlists...${NC}"
for f in wordlists/users.txt wordlists/passwords.txt; do
  if [ -f "$f" ]; then
    count=$(wc -l < "$f")
    echo -e "  ${GREEN}[✓]${NC} $f ($count entradas)"
  else
    echo -e "  ${RED}[✗]${NC} $f não encontrada"
  fi
done

echo -e "\n${GREEN}[✓] Ambiente verificado! Pronto para os testes.${NC}"
echo "=============================================="
echo "  Próximo passo — Cenário 1 FTP:"
echo "  medusa -h $TARGET -U wordlists/users.txt -P wordlists/passwords.txt -M ftp -t 3 -v 6"
echo "=============================================="
