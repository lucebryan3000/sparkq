# KB-Codex Agent Quick Start

Get started with the KB-Codex AI agent in 60 seconds.

## 🚀 Quick Test

### Option 1: Natural Language (Simplest)

Just ask Claude Code:

```
"Generate a KB2 article about Docker Networking"
```

Claude Code will automatically detect that you want to use the KB2 system and engage the kb-codex-agent.

### Option 2: Direct Agent Invocation

```
Launch kb-codex-agent to generate an article about FastAPI async patterns
```

### Option 3: Use Task Tool (Programmatic)

In Claude Code session:

```python
Task(
    subagent_type="kb-codex-agent",
    description="Generate KB article",
    prompt="Generate a comprehensive article about Redis caching best practices"
)
```

## 🎯 Top 5 Most Useful Commands

### 1. Generate an Article

```
Launch kb-codex-agent to generate an article about [TOPIC]
```

**Example**:
```
Launch kb-codex-agent to generate an article about PostgreSQL Indexing
```

**What it does**:
- Navigates to `/home/luce/apps/KB2`
- Activates virtual environment
- Runs `python kb2-codex-generator-cli.py "PostgreSQL Indexing"`
- Shows quality metrics (words, code blocks, score)

---

### 2. Check Queue Status

```
Launch kb-codex-agent to check the queue status
```

**What it does**:
- Reads `/home/luce/apps/KB2/data/queue.json`
- Shows pending, completed, and failed topics
- Displays progress statistics

---

### 3. Search Knowledge Base

```
Launch kb-codex-agent to search the KB for [QUERY]
```

**Example**:
```
Launch kb-codex-agent to search the KB for "Docker networking best practices"
```

**What it does**:
- Runs semantic search via ChromaDB
- Returns top 5 relevant sections
- Shows relevance scores
- Provides article file paths

---

### 4. Validate Articles

```
Launch kb-codex-agent to validate all articles
```

**What it does**:
- Runs validation on all articles in `data/articles/`
- Checks word count, code blocks, structure
- Assigns quality scores (0-100)
- Reports pass/fail status

---

### 5. Process Queue

```
Launch kb-codex-agent to process the queue
```

**What it does**:
- Reads all pending topics from queue
- Generates articles for each topic
- Validates generated articles
- Updates queue status

## 📚 Real-World Examples

### Example 1: Single Article Generation (Full Workflow)

```
Launch kb-codex-agent to:
1. Research "Docker Compose" via DuckDuckGo
2. Generate a complete article
3. Validate the quality
4. Ingest into ChromaDB
5. Report the quality metrics
```

**Expected Output**:
```
Research: Cached 12 sources (authority score: 85/100)
Article: 8,500 words, 42 code blocks
Quality: 97/100 (A+ Excellent)
ChromaDB: Ingested 15 sections
```

---

### Example 2: Batch Processing

```
Launch kb-codex-agent to:
1. Add topics from config/batch-topics-100.txt to the queue
2. Process the first 10 topics
3. Validate all generated articles
4. Show quality statistics
```

**Expected Output**:
```
Queue: Added 100 topics
Generated: 10 articles
Pass rate: 90%
Average quality: 94/100
```

---

### Example 3: Knowledge Base Query

```
Launch kb-codex-agent to search the KB for information about:
- FastAPI authentication
- Docker networking
- PostgreSQL optimization
```

**Expected Output**:
```
Found 15 relevant sections across 3 articles:

FastAPI Authentication:
1. Implementation Guide (score: 0.95)
2. Best Practices (score: 0.92)
3. Code Examples (score: 0.89)

Docker Networking:
1. Technical Architecture (score: 0.94)
...
```

---

### Example 4: Quality Assurance

```
Launch kb-codex-agent to:
1. Validate all articles
2. Identify articles with quality < 70
3. List specific quality issues
4. Suggest improvements
```

**Expected Output**:
```
Total articles: 18
Passed (≥70): 16 (89%)
Failed (<70): 2 (11%)

Failed articles:
- topic-1.md: Score 65 (insufficient code examples)
- topic-2.md: Score 68 (word count too low)

Recommendations:
- Regenerate topic-1 with --model "gpt-5-codex high"
- Increase timeout for topic-2 to 600s
```

## 🛠️ Direct CLI Commands (What Agent Runs)

If you want to run commands directly without the agent:

### Generate Article
```bash
cd /home/luce/apps/KB2
source venv/bin/activate
python kb2-codex-generator-cli.py "Docker Networking"
```

### Queue Status
```bash
cd /home/luce/apps/KB2
source venv/bin/activate
python kb2-codex-generator-cli.py --queue-status
```

### Search KB
```bash
cd /home/luce/apps/KB2
source venv/bin/activate
python src/kb2.py query "Docker networking"
```

### Validate All
```bash
cd /home/luce/apps/KB2
source venv/bin/activate
python src/kb2.py validate
```

## 💡 Pro Tips

### Tip 1: Specify Model for Quality
```
Launch kb-codex-agent to generate article about [TOPIC] using model "gpt-5-codex high"
```

### Tip 2: Research First
```
Launch kb-codex-agent to:
1. Research "Kubernetes Operators"
2. Then generate article using the research
```

### Tip 3: Batch Operations
```
Launch kb-codex-agent to add these topics to queue:
- Docker BuildKit
- FastAPI Middleware
- PostgreSQL Connection Pooling
```

### Tip 4: Quality Checks
```
Launch kb-codex-agent to generate article about Redis and ensure quality score > 90
```

### Tip 5: Parallel Tasks
```
Launch two agents in parallel:
1. kb-codex-agent: Process queue
2. general-purpose: Monitor system resources
```

## 🐛 Troubleshooting

### Agent says "Module not found"

**Cause**: Virtual environment not activated

**Fix**: Agent should auto-activate. If it doesn't:
```bash
cd /home/luce/apps/KB2
source venv/bin/activate
```

---

### Agent can't connect to ChromaDB

**Cause**: ChromaDB not running

**Fix**:
```bash
# Check if running
curl http://localhost:8002/api/v2/heartbeat

# If not, start ChromaDB
docker start chromadb
```

---

### Low quality scores

**Cause**: Default model may not be optimal

**Fix**:
```
Launch kb-codex-agent to regenerate [TOPIC] using "gpt-5-codex high" model
```

---

### Queue not processing

**Cause**: Queue file might be corrupted or locked

**Fix**:
```
Launch kb-codex-agent to:
1. Show queue status
2. Clear any stuck topics
3. Restart queue processing
```

## 📖 Next Steps

### Learn More
- Read `.claude/README.md` for full agent documentation
- Read `.claude/agents/kb-codex-agent.md` for complete capabilities
- Read `/home/luce/apps/KB2/KB2-README.md` for system overview

### Try Advanced Features
```
Launch kb-codex-agent to:
1. Generate 5 articles on advanced Python topics
2. Validate and show quality distribution
3. Ingest to ChromaDB
4. Create metrics dashboard
```

### Customize Agent
Edit `.claude/agents/kb-codex-agent.md` to:
- Add new workflows
- Modify quality thresholds
- Add custom commands
- Update system knowledge

## 🎯 Success Checklist

After reading this guide, you should be able to:

- ✅ Generate a single article via agent
- ✅ Check queue status
- ✅ Search the knowledge base
- ✅ Validate article quality
- ✅ Process batch operations
- ✅ Troubleshoot common issues

## 🎉 You're Ready!

Try your first command:

```
Launch kb-codex-agent to show me all generated articles
```

Or:

```
Launch kb-codex-agent to generate an article about your favorite tech topic
```

---

**Guide Version**: 1.0
**Last Updated**: 2025-10-01
**Estimated Reading Time**: 5 minutes
**Skill Level**: Beginner-friendly
