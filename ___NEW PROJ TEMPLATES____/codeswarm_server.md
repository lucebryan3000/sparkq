# Codeswarm Development Server - System Capabilities

**Last Updated:** 2025-12-07
**System Uptime:** 3 days, 9 hours
**Hostname:** codeswarm

---

## Quick Reference

| Resource | Specification | AI Assistant Guidance |
|----------|--------------|----------------------|
| **CPU Cores** | 24 (16 physical, 2 threads/core) | Safe to run 16-20 parallel build tasks |
| **Available RAM** | 118 GiB available (123 GiB total) | Can allocate up to 100GB for Docker/VMs |
| **GPU VRAM** | 10 GB (9.8 GB free) | Available for local LLM inference, ML training |
| **Fast Storage** | 2x NVMe drives (2TB + 1TB) | Use NVMe for build artifacts, node_modules |
| **Network** | 1Gbps ethernet + Tailscale VPN | Low-latency remote development capable |

---

## 1. CPU Capabilities

### Hardware
- **Model:** Intel Core i9-12900F (12th Gen, Alder Lake)
- **Architecture:** x86_64 hybrid (P-cores + E-cores)
- **Total Logical CPUs:** 24
- **Physical Cores:** 16
- **Threads per Core:** 2 (Hyperthreading enabled)
- **Max Frequency:** 5.1 GHz
- **Min Frequency:** 800 MHz
- **Current Scaling:** 24% average utilization

### Cache Hierarchy
- **L1d Cache:** 640 KiB (16 instances)
- **L1i Cache:** 768 KiB (16 instances)
- **L2 Cache:** 14 MiB (10 instances)
- **L3 Cache:** 30 MiB (shared)

### Performance Status
- **Governor:** `powersave` ⚠️ **OPTIMIZATION OPPORTUNITY**
- **Virtualization:** VT-x enabled
- **Current Load:** 0.75 (1min), 0.36 (5min), 0.13 (15min)

### AI Assistant Recommendations
- **Max Parallel Jobs:** 16-20 for CPU-bound tasks (matches physical cores)
- **Docker CPU Limits:** Can safely allocate 20 CPUs to containers
- **Build Optimization:** Use `-j20` for Make, `--max-workers=20` for Webpack
- ⚠️ **Action Item:** Consider setting governor to `performance` for build-heavy workloads

---

## 2. Memory

### RAM Configuration
- **Total:** 123.3 GiB (129,316 MB)
- **Available:** 118 GiB (currently)
- **Used:** 4.4 GiB (base system)
- **Cached/Buffers:** 60 GiB
- **Type:** Unknown (requires `sudo dmidecode`)
- **Speed:** Unknown (requires sudo access)

### Swap Configuration
- **Total Swap:** 8 GiB
- **Swap Used:** 0 B (none currently)
- **Swap Type:** File-based (`/swap.img`)
- **Swappiness:** 60 (default)

### AI Assistant Recommendations
- **Docker Memory Limits:** Safe to allocate 100+ GB to containers
- **Node.js Memory:** Can set `--max-old-space-size=32768` (32GB) for large builds
- **Python ML Models:** Can load models up to ~100GB in RAM
- **Memory-Intensive Tasks:** Elasticsearch, Redis, PostgreSQL all fit comfortably
- ⚠️ **Optional Optimization:** Lower swappiness to 10 for performance workloads

---

## 3. GPU Capabilities

### Hardware
- **Model:** NVIDIA GeForce RTX 3080
- **Architecture:** Ampere (GA102)
- **Total VRAM:** 10,240 MiB (10 GB)
- **Free VRAM:** 9,809 MiB (~9.8 GB available)
- **Current Utilization:** 0%
- **Temperature:** 44°C (idle)
- **PCIe:** Gen 4 capable (currently Gen 1)

### Driver & Software
- **Driver Version:** 580.95.05
- **CUDA Version:** 13.0 (driver supports)
- **CUDA Toolkit:** Not installed ⚠️
- **Persistence Mode:** Disabled

### AI/ML Capabilities
✅ **Available for:**
- Local LLM inference (Llama, Mistral models up to ~8B parameters)
- Fine-tuning small models
- Stable Diffusion image generation
- PyTorch/Transformers workloads

❌ **Limitations:**
- CUDA toolkit not installed (Python can use via PyTorch CUDA wheels)
- No Ollama installed for easy LLM serving
- PCIe running at Gen 1 (potential bottleneck for data transfer)

### AI Assistant Recommendations
- **LLM Inference:** Can run 7B-8B parameter models comfortably
- **Batch Processing:** 10GB VRAM supports batch size ~16-32 for most models
- **Docker GPU Access:** NVIDIA runtime installed, use `--gpus all`
- ⚠️ **Action Item:** Install Ollama for easy local LLM deployment
- ⚠️ **Action Item:** Install CUDA toolkit if doing ML development

---

## 4. Storage

### Storage Devices

| Device | Type | Size | Speed | Model |
|--------|------|------|-------|-------|
| **nvme1n1** | NVMe | 1.8 TB | High-speed | Samsung 990 PRO with Heatsink |
| **nvme0n1** | NVMe | 953.9 GB | High-speed | Samsung PM9A1 |
| **sda** | USB-Attached | 931.5 GB | USB 3.2 | ASM236X NVME (external) |
| **sdb** | USB | 114.6 GB | USB 3.2 | SanDisk 3.2Gen1 |

### Mounted Filesystems

| Mount Point | Filesystem | Size | Used | Available | Use% |
|-------------|-----------|------|------|-----------|------|
| **/** (root) | /dev/sda2 | 885 GB | 453 GB | 388 GB | 54% |
| **/boot/efi** | /dev/sda1 | 1.1 GB | 6.2 MB | 1.1 GB | 1% |
| **/tmp** | tmpfs | 62 GB | 29 MB | 62 GB | <1% |

### I/O Scheduler
- **NVMe drives:** `mq-deadline` (default, optimal for NVMe)
- **USB drives:** `mq-deadline`

### AI Assistant Recommendations
- **Fast Build Storage:** Use NVMe drives for:
  - `node_modules/` directories
  - Build artifacts
  - Docker volumes requiring high IOPS
  - Database storage (PostgreSQL, Redis)

- **Large File Storage:** Use root filesystem (sda2) has 388GB free
- **Temporary Files:** `/tmp` is tmpfs (RAM-backed, 62GB available)
- **Docker Root:** `/var/lib/docker` on main drive

---

## 5. Docker Configuration

### Installation
- **Docker Version:** 28.2.2 (latest)
- **Docker Compose:** v2.40.3
- **Storage Driver:** overlay2 (optimal)
- **Backing Filesystem:** extfs
- **Cgroup Version:** 2
- **Init System:** systemd

### Container Status
- **Total Containers:** 13
- **Running:** 2 (bloom_app, bloom_postgres)
- **Stopped:** 11
- **Total Images:** 56

### Resource Usage

| Type | Total | Active | Size | Reclaimable |
|------|-------|--------|------|-------------|
| **Images** | 30 | 13 | 38.92 GB | 5.14 GB (13%) |
| **Containers** | 13 | 2 | 415.6 MB | 208.4 MB (50%) |
| **Volumes** | 33 | 10 | 217.5 GB | 146.3 GB (67%) |
| **Build Cache** | 92 | 0 | 939 MB | 939 MB (100%) |

### Networks
- `bloom2_bloom_network` (bridge)
- `bridge` (default)
- `host`
- `llm_net` (bridge)
- `none` (null)

### Running Containers

| Container | CPU % | Memory | Memory Limit | Status |
|-----------|-------|--------|--------------|--------|
| **bloom_app** | 0.00% | 1.9 MiB | 6 GiB | Running (1 process) |
| **bloom_postgres** | 0.00% | 101 MiB | 123.3 GiB | Running (6 processes) |

### GPU Support
- **NVIDIA Runtime:** Installed and available
- **Default Runtime:** runc
- **GPU Access:** Use `--gpus all` or `--runtime=nvidia`

### AI Assistant Recommendations
- **Cleanup Opportunity:** 146GB reclaimable in volumes, 939MB in build cache
- **Memory Available:** 118GB RAM available for new containers
- **CPU Available:** 24 cores, current load minimal
- **Network Isolation:** Custom bridge networks available for microservices
- **Volume Strategy:** Consider pruning unused volumes periodically

---

## 6. Network Configuration

### Network Interfaces

| Interface | Status | IP Address | Type |
|-----------|--------|------------|------|
| **enp4s0** | UP | 192.168.1.150/24 | Ethernet (primary) |
| **tailscale0** | UP | 100.86.53.79/32 | VPN (Tailscale) |
| **wg0** | UP | 10.0.0.1/24 | VPN (WireGuard) |
| **wlp5s0** | DOWN | - | WiFi (disabled) |
| **docker0** | DOWN | 172.17.0.1/16 | Docker bridge |
| **br-b9372e72868b** | UP | 172.19.0.1/16 | Docker custom bridge |

### DNS Configuration
- **Nameserver:** 127.0.0.53 (systemd-resolved)
- **Search Domain:** taila8a782.ts.net (Tailscale)
- **EDNS0:** Enabled
- **DNSSEC:** Trust-ad enabled

### VPN Status
- **Tailscale:** ✅ Active (100.86.53.79)
- **WireGuard:** ✅ Active (10.0.0.1)
- **Remote Access:** Dual VPN for redundancy

### AI Assistant Recommendations
- **Development Access:** Use Tailscale IP for secure remote development
- **Container Networking:** Use custom bridge networks for isolation
- **Port Exposure:** SSH configured on default port, root login disabled
- **DNS Resolution:** systemd-resolved handles local and network DNS

---

## 7. Development Tools

### Node.js Ecosystem
- **Node.js:** v20.18.1 (LTS)
- **npm:** 10.8.2
- **pnpm:** 9.15.0 ✅ (fast, efficient package manager)
- **NVM:** Installed (manages Node versions)

### Python Ecosystem
- **Python:** 3.13.3 (latest)
- **pip:** 25.0
- **Location:** `/usr/bin/python3`
- **ML Libraries:**
  - ✅ PyTorch 2.8.0
  - ✅ Transformers 4.56.2
  - ✅ Sentence-Transformers 5.1.1
  - ✅ NumPy 2.3.3

### Rust Toolchain
- **rustc:** 1.91.1
- **cargo:** 1.91.1

### Build Tools
- **Make:** GNU Make 4.4.1
- **GCC:** 14.2.0 (Ubuntu)
- **CMake:** Not installed ❌

### Not Installed
- ❌ Go
- ❌ Java
- ❌ CMake

### AI Assistant Recommendations
- **Node Projects:** Use `pnpm` for faster installs and disk savings
- **Python ML:** GPU-accelerated PyTorch ready, can run transformers locally
- **Rust Builds:** Full toolchain available for Rust development
- **C/C++ Builds:** GCC installed, consider installing CMake if needed

---

## 8. AI/ML Tools

### Installed
- ✅ **Codex CLI:** v0.65.0 (at `/home/luce/.nvm/versions/node/v20.18.1/bin/codex`)
- ✅ **Claude Code:** Installed (aliased to `/home/luce/.claude/local/claude`)
- ✅ **PyTorch:** 2.8.0 with CUDA support
- ✅ **Transformers:** 4.56.2 (Hugging Face)
- ✅ **Sentence-Transformers:** 5.1.1 (embeddings)

### Not Installed
- ❌ **Ollama** (for easy local LLM serving)
- ❌ **CUDA Toolkit** (driver has CUDA 13.0, but toolkit not installed)

### GPU ML Readiness
- **Status:** ✅ Ready for inference, ⚠️ needs CUDA toolkit for development
- **VRAM:** 10GB available
- **PyTorch CUDA:** Available (uses bundled CUDA runtime)
- **Model Size Guidance:**
  - 7B parameter models: ✅ Comfortable
  - 13B parameter models: ⚠️ Tight (quantized/4-bit recommended)
  - 30B+ parameter models: ❌ Insufficient VRAM

### AI Assistant Recommendations
- **Local LLM Inference:** Install Ollama for easy model serving
- **Embedding Generation:** Sentence-transformers ready for RAG pipelines
- **ML Development:** Install CUDA toolkit if compiling custom CUDA kernels
- **Model Serving:** Can run local API endpoints for AI features

---

## 9. Resource Limits & Kernel Tuning

### File Descriptor Limits
- **User limit (soft):** 1,073,741,816 (~1B)
- **System-wide max:** 9,223,372,036,854,775,807 (essentially unlimited)
- **Status:** ✅ No concerns

### Process Limits
- **Max user processes:** 503,306
- **Status:** ✅ Adequate for heavy multitasking

### File Watcher Limits (inotify)
- **max_user_watches:** 996,453
- **Status:** ✅ Good for development (supports large monorepos)
- **Recommendation:** Increase to 524,288 if using very large monorepos

### Network Tuning
- **somaxconn:** 4096 (connection backlog)
- **Status:** ✅ Good for web servers under load

### Memory Management
- **Swappiness:** 60 (default)
- **Recommendation:** ⚠️ Lower to 10 for performance workloads

### AI Assistant Recommendations
- **Large Projects:** File watcher limit supports ~1M files
- **Web Servers:** somaxconn = 4096 handles moderate load well
- **No Bottlenecks:** Resource limits won't constrain typical development

---

## 10. Running Services

### Active System Services
- ✅ **Docker** (container runtime)
- ✅ **nginx** (reverse proxy)
- ✅ **Redis** (key-value store)
- ✅ **PostgreSQL** (via Docker containers)
- ✅ **NVIDIA Persistence Daemon** (GPU driver)
- ✅ **Tailscale** (VPN mesh network)
- ✅ **Samba** (NMB daemon for file sharing)

### Custom CodeSwarm Services
- ✅ **ccui-backend.service** (CCUI Backend API Server)
- ✅ **codeswarm-home.service** (Homer Dashboard)
- ✅ **menu-backend.service** (Menu Backend API)

### Background Jobs (Cron)

| Schedule | Task | Log |
|----------|------|-----|
| **Daily 9am** | RAG monitoring | `/home/luce/logs/rag-daily.log` |
| **Daily 2am** | System backup | `/home/luce/logs/backup.log` |
| **Daily 1am** | Container hosts update | - |
| **Daily 2am** | Quick backup | - |
| **Every 4h** | Code indexing | `/home/luce/logs/code_indexing.log` |

**Disabled Jobs (2025-10-08):**
- System watchdog (reduced polling)
- Docker health manager (reduced polling)
- Simple alerts (reduced polling)

### AI Assistant Recommendations
- **Available Ports:** Check with `ss -tlnp` before binding new services
- **Service Conflicts:** Redis, nginx, Docker already running
- **Log Locations:** Cron logs in `/home/luce/logs/`

---

## 11. Security & Access

### SSH Configuration
- **Root Login:** ❌ Disabled (`PermitRootLogin no`)
- **Password Auth:** ❌ Disabled (key-based only)
- **Default Port:** Yes (not explicitly set in config)

### Firewall Status
- **ufw:** Not accessible (requires sudo)
- **Fail2ban:** Not installed

### Active Users
- **Current Sessions:** 2 SSH sessions
  - luce @ pts/7 (from 192.168.1.2)
  - luce @ pts/0 (from 192.168.1.2)

### AI Assistant Recommendations
- ✅ **Security Posture:** SSH hardened (no root, no passwords)
- ⚠️ **Firewall:** Unknown status (requires sudo to check)
- ✅ **VPN Access:** Tailscale provides secure remote access

---

## 12. Optimization Opportunities

### High Priority
1. **CPU Governor:** Change from `powersave` to `performance` for build workloads
   ```bash
   echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

2. **Docker Cleanup:** Reclaim 146GB from unused volumes
   ```bash
   docker volume prune -f
   docker builder prune -af
   ```

### Medium Priority
3. **Swappiness:** Lower from 60 to 10 for performance
   ```bash
   sudo sysctl vm.swappiness=10
   echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
   ```

4. **Install Ollama:** Enable easy local LLM serving
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```

5. **Install CUDA Toolkit:** For ML development (if needed)
   ```bash
   sudo apt install nvidia-cuda-toolkit
   ```

### Low Priority
6. **PCIe Gen 4:** GPU running at Gen 1 (check physical connection)
7. **inotify watches:** Increase to 524,288 for very large projects
8. **Install CMake:** If C/C++ projects need it

---

## 13. AI Assistant Usage Guidelines

### Parallel Processing Recommendations

**Safe Parallelism Levels:**
- **CPU-bound tasks:** `-j16` to `-j20` (matches physical cores)
- **Docker builds:** `--parallel 4-8` (avoid memory pressure)
- **Test runners:** `--max-workers=16`
- **File processing:** Up to 20 concurrent workers

**Memory Allocation:**
- **Node.js:** `--max-old-space-size=32768` (32GB) safe
- **Python ML models:** Up to 100GB in RAM
- **Docker containers:** 100GB total allocation safe
- **Build caches:** 20-30GB safe for large projects

**Storage Strategy:**
- **Fast (NVMe):** Build artifacts, node_modules, databases
- **Standard (root):** Source code, Docker images, logs
- **Temporary (tmpfs):** Ephemeral build files (62GB RAM available)

**GPU Utilization:**
- **LLM Inference:** 7B-8B models run comfortably
- **Batch size:** 16-32 for most transformer models
- **VRAM buffer:** Keep 1-2GB free for system
- **Docker GPU:** Use `--gpus all` flag

### Common Task Configurations

**Large Node.js Build:**
```bash
NODE_OPTIONS="--max-old-space-size=32768" pnpm build --max-workers=16
```

**Docker Compose with GPU:**
```yaml
services:
  ml-service:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

**Parallel Test Execution:**
```bash
pytest -n 16  # 16 parallel workers
jest --maxWorkers=16
```

---

## Summary

**Codeswarm is a high-performance development server with:**
- 💪 24-core CPU capable of heavy parallel builds
- 🧠 123GB RAM for large-scale development
- 🎮 RTX 3080 (10GB VRAM) for ML/AI workloads
- 💾 Fast NVMe storage for build performance
- 🐳 Docker with GPU support
- 🔧 Modern development tooling (Node, Python, Rust)
- 🤖 AI/ML libraries ready for local inference

**Key Strengths:**
- Massive RAM allows multiple large projects simultaneously
- GPU enables local LLM inference and ML development
- Fast storage minimizes build times
- Dual VPN setup enables secure remote development

**Action Items for Optimal Performance:**
- Set CPU governor to `performance`
- Clean up Docker volumes (146GB reclaimable)
- Install Ollama for easy LLM deployment
- Lower swappiness for performance workloads

---

*Server documentation for AI assistants. Include in project context when working on Codeswarm-hosted projects.*
