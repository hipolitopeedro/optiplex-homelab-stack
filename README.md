# Dell OptiPlex LGA 1155 Homelab Stack (Core i5-3470 | 8GB DDR3 | 3TB HDD)

![Docker](https://img.shields.io/badge/Docker_Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Linux](https://img.shields.io/badge/Linux_Headless-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash_Automation-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)

> **Live Interactive Homelab Resource & 3TB Storage Planner (GitHub Pages):** [https://hipolitopeedro.github.io/optiplex-homelab-stack/](https://hipolitopeedro.github.io/optiplex-homelab-stack/)
>
> **Português:** Infraestrutura completa de **Nuvem Pessoal, Mídia, Adblock e Jogos** em containers (`Docker Compose`) e scripts Bash projetada sob medida para um **Home Server Dell OptiPlex LGA 1155 (Intel Core i5-3470 4C/4T, 8GB RAM DDR3, GeForce GT 710 1GB e HD de 3TB)** — inspirado nos servidores caseiros clássicos de reaproveitamento de hardware (estilo *1155 do ET*), mas com engenharia limpa, limites estritos de memória RAM e auditoria de saúde física `S.M.A.R.T.` do disco de 3TB.
>
> **English:** Complete **Personal Cloud, Media, Adblock & Game Server** infrastructure (`Docker Compose` & Bash) tailored for a **Dell OptiPlex LGA 1155 Home Server (Intel Core i5-3470 4C/4T, 8GB DDR3 RAM, GeForce GT 710 1GB, and 3TB HDD)**. Combines **Immich** (self-hosted Google Photos), **Jellyfin** (self-hosted Netflix), **Navidrome** (self-hosted Spotify), **Samba SMB3 + FileBrowser** (3TB LAN/Web NAS), **Pi-hole** (network-wide DNS adblocker), and a tuned **PaperMC Minecraft server** with RCON-safe local backups and `S.M.A.R.T.` disk health monitoring.

---

## Services Included on the 3TB HDD / Serviços Inclusos

| Service / Serviço | Role / Função ("Equivalente") | Port / Porta | RAM Limit (`mem_limit`) | 3TB HDD Path (`/mnt/storage3tb`) |
| :--- | :--- | :--- | :--- | :--- |
| **Immich** (`server` + `pg` + `redis`) | **Google Fotos Caseiro** (Backup automático das fotos e vídeos do celular via Wi-Fi) | `:2283` | `~1.0 GB` (Sem ML pesado p/ poupar os 8GB) | `/mnt/storage3tb/photos` |
| **Samba (SMB3)** | **Servidor de Arquivos na Rede (NAS)** mapeado direto no Windows Explorer (`\\IP\Pedro_3TB`) | `:445` | `256 MB` | `/mnt/storage3tb/shares` |
| **FileBrowser** | **Google Drive Caseiro** (Gerenciador de arquivos via navegador web e celular) | `:8081` | `192 MB` | `/mnt/storage3tb/{shares,media,photos}` |
| **Jellyfin** | **Netflix Caseira** (Streaming de filmes, séries e vídeos pessoais para TV/Celular/PC) | `:8096` | `512 MB` | `/mnt/storage3tb/media/{movies,series,videos}` |
| **Navidrome** | **Spotify Caseiro** (Streaming super leve de músicas MP3/FLAC) | `:4533` | `128 MB` | `/mnt/storage3tb/media/music` |
| **Pi-hole** | **Adblock de Rede** (Bloqueia anúncios e telemetria via DNS em todos os aparelhos da casa) | `:53` / `:8080` | `200 MB` | `/mnt/storage3tb/appdata/pihole` |
| **Minecraft (PaperMC)** | **Servidor Java 21 + Aikar's Flags** com **Auto-Pause** (dorme após 15 min vazio para liberar CPU/RAM) | `:25565` | `3.5 GB` Heap (`4.2 GB` limit) | `/mnt/storage3tb/minecraft_data` |

---

## Repository Structure / Estrutura do Repositório

| File / Arquivo | Description / Descrição |
| :--- | :--- |
| [`docker-compose.yml`](docker-compose.yml) | Stack unificada com `pihole`, `samba`, `filebrowser`, `immich` (`server` + `postgres` + `redis`), `jellyfin`, `navidrome` e `minecraft` (`PaperMC` + `USE_AIKAR_FLAGS=true` + `ENABLE_AUTOPAUSE=TRUE`). |
| [`.env.example`](.env.example) | Variáveis de ambiente centralizadas (IP do OptiPlex na LAN, senhas do Samba/Pi-hole/Immich, portas e Heap do Minecraft). |
| [`scripts/bootstrap-optiplex.sh`](scripts/bootstrap-optiplex.sh) | Cria toda a árvore de pastas no HD de 3TB (`/mnt/storage3tb`), desativa o `systemd-resolved` na porta `53` e aplica ajustes de Kernel (`sysctl`) para 8GB DDR3 e rede Gigabit (`TCP BBR`). |
| [`scripts/backup-local-3tb.sh`](scripts/backup-local-3tb.sh) | Backup 100% local na partição `/mnt/storage3tb/backups`: faz flush seguro do mundo do Minecraft via RCON, dump `.sql.gz` do banco PostgreSQL do Immich e backup do Pi-hole com hash `SHA-256` e retenção de 14 dias. |
| [`scripts/hdd-smart-health-audit.sh`](scripts/hdd-smart-health-audit.sh) | Inspeciona a saúde física `S.M.A.R.T.` do HD de 3TB (`smartctl` — temperatura, horas de uso, *Reallocated Sectors* e *Pending Sectors*) e mostra o consumo de espaço por pasta. |

---

## Quick Start / Como Subir no OptiPlex

```bash
# 1. Clonar o repositório no OptiPlex (Ubuntu Server / Debian Headless)
git clone https://github.com/hipolitopeedro/optiplex-homelab-stack.git
cd optiplex-homelab-stack

# 2. Preparar o HD de 3TB (/mnt/storage3tb), liberar a porta 53 e aplicar tuning do Linux
chmod +x scripts/*.sh
sudo ./scripts/bootstrap-optiplex.sh

# 3. Configurar suas senhas e o IP fixo da LAN
cp .env.example .env
nano .env

# 4. Subir toda a nuvem caseira + servidor de Minecraft
docker compose up -d
```
