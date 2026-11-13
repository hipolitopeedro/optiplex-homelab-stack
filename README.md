# Dell OptiPlex Homelab Stack (Core i5-3470 | 8GB DDR3 | 3TB HDD)

![Docker](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux_Headless-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash_Automation-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)

> **Live Interactive Homelab Resource & Storage Planner (GitHub Pages):** [https://hipolitopeedro.github.io/optiplex-homelab-stack/](https://hipolitopeedro.github.io/optiplex-homelab-stack/)
>
> **Português:** Infraestrutura completa em containers (`Docker Compose`) e scripts de automação em Bash projetados sob medida para um **Home Server Dell OptiPlex (Intel Core i5-3470 4C/4T, 8GB RAM DDR3, GeForce GT 710 1GB e HD de 3TB)**. Reúne bloqueador de anúncios para toda a rede (**Pi-hole**), servidor de arquivos local Gigabit (**Samba SMB3 + FileBrowser Web** sobre os **3TB de HDD**) e servidor de **Minecraft (PaperMC com Aikar's Flags e Auto-Pause)** com rotinas de backup local rotativo e auditoria física `S.M.A.R.T.` do disco.
>
> **English:** Containerized infrastructure (`Docker Compose`) and Bash automation scripts tailored for a **Dell OptiPlex Home Server (Intel Core i5-3470 4C/4T, 8GB DDR3 RAM, GeForce GT 710 1GB, and 3TB HDD)**. Runs a network-wide DNS adblocker (**Pi-hole**), a Gigabit LAN file server (**Samba SMB3 + FileBrowser Web** backed by the **3TB HDD**), and a tuned **Minecraft PaperMC server (Aikar's JVM Flags + Auto-Pause)** with RCON-safe local backups and `S.M.A.R.T.` disk health monitoring.

---

## Hardware Target & Resource Allocation / Alocação de Hardware

| Resource / Recurso | Spec / Especificação | Allocation Strategy / Estratégia de Alocação |
| :--- | :--- | :--- |
| **CPU** | Intel Core i5-3470 (4C/4T @ 3.20–3.60 GHz) | `3.0 cores` para o PaperMC (Minecraft), `1.0 core` para o Samba SMB3 e `0.5 core` para Pi-hole/FileBrowser. |
| **Memory (RAM)** | `8 GB DDR3` | `4.0 GB` JVM Heap (`4.7 GB` container limit) para o Minecraft + `256 MB` Pi-hole + `256 MB` Samba + `192 MB` FileBrowser + **`~2.6 GB` livres** para o Kernel Linux e Page Cache de disco do Samba. |
| **Storage** | `3 TB Mechanical HDD` (`/mnt/storage3tb`) | Montado com `noatime` e `vm.dirty_ratio=15`. Dividido em `/shares` (NAS da rede), `/minecraft_data` (mundo ativo) e `/backups` (snapshots comprimidos `.tar.gz` com 14 dias de retenção). |
| **GPU** | NVIDIA GeForce GT 710 1GB DDR3 | Saída de vídeo local de baixíssimo consumo para console físico de emergência (servidor roda em modo *headless* via SSH). |

---

## Repository Structure / Estrutura do Repositório

| File / Arquivo | Description / Descrição |
| :--- | :--- |
| [`docker-compose.yml`](docker-compose.yml) | Stack completa com `pihole`, `samba` (SMB2/SMB3 com `TCP_NODELAY` e `aio`), `filebrowser` e `minecraft` (`PaperMC` + `USE_AIKAR_FLAGS=true` + `ENABLE_AUTOPAUSE=TRUE`). |
| [`.env.example`](.env.example) | Variáveis de ambiente (IP local do servidor, credenciais do Samba/Pi-hole, versão do Minecraft, distância de renderização e senha RCON). |
| [`scripts/bootstrap-optiplex.sh`](scripts/bootstrap-optiplex.sh) | Cria a estrutura de diretórios no HD de 3TB (`/mnt/storage3tb`), libera a porta `53` do `systemd-resolved` para o Pi-hole e aplica otimizações de kernel (`sysctl`) para 8GB RAM e rede Gigabit (`TCP BBR`). |
| [`scripts/backup-local-3tb.sh`](scripts/backup-local-3tb.sh) | Faz backup consistente do mundo do Minecraft (pausa a escrita via `rcon-cli save-off` / `save-all flush` antes de compactar) e do Pi-hole direto na partição `/mnt/storage3tb/backups` com manifesto `SHA-256`. |
| [`scripts/hdd-smart-health-audit.sh`](scripts/hdd-smart-health-audit.sh) | Audita a saúde física do HD de 3TB via `smartctl` (temperatura, horas ligado, *Reallocated Sectors* e *Pending Sectors*) e exibe o uso de espaço por pasta. |

---

## Quick Start / Como Subir no OptiPlex

```bash
# 1. Clonar o repositório no OptiPlex (Ubuntu Server / Debian)
git clone https://github.com/hipolitopeedro/optiplex-homelab-stack.git
cd optiplex-homelab-stack

# 2. Preparar o HD de 3TB (/mnt/storage3tb), liberar a porta 53 e aplicar tuning do Linux
chmod +x scripts/*.sh
sudo ./scripts/bootstrap-optiplex.sh

# 3. Configurar suas senhas e o IP da LAN
cp .env.example .env
nano .env

# 4. Subir todos os serviços em background
docker compose up -d
```

### Acessos na Rede Local (Exemplo com IP `192.168.1.250`):
* **Pi-hole Admin (Adblock)**: `http://192.168.1.250:8080/admin` *(Configure `192.168.1.250` como DNS primário no roteador da sua casa)*
* **Servidor de Arquivos no Windows Explorer**: `\\192.168.1.250\Pedro_3TB` e `\\192.168.1.250\Public`
* **FileBrowser (Painel Web de Arquivos 3TB)**: `http://192.168.1.250:8081`
* **Servidor de Minecraft (Java Edition)**: `192.168.1.250:25565`
