# Git Workflow & Team Collaboration Guide

Hướng dẫn commit strategy, branch management, và collaboration cho nhóm 4 người.

---

## 🌳 Branch Strategy

### Main branches:
- **`main`**: Production-ready code (stable)
- **`develop`**: Development branch (all features integrated)

### Feature branches:
- **`feature/feature-name`**: New features
- **`fix/bug-name`**: Bug fixes
- **`test/testing-setup`**: Testing & CI/CD

### Naming convention:
```
feature/event-approval
feature/saved-events
fix/registration-count-bug
test/add-unit-tests
docs/api-documentation
```

---

## 👥 Team Members & Responsibilities

| Person | Role | Branches | Main Focus |
|--------|------|----------|-----------|
| Người 1 | Backend Lead | backend/* | API, models, business logic |
| Người 2 | Database/Admin | admin/* | Admin features, DB schema |
| Người 3 | Frontend Lead | frontend/* | UI, user flows, widgets |
| Người 4 | CI/Testing | test/* | Testing, CI/CD, quality |

---

## 📋 Commit Message Format

### Format:
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types:
- **feat**: Thêm feature mới
- **fix**: Sửa bug
- **test**: Thêm/cập nhật test
- **docs**: Cập nhật documentation
- **refactor**: Refactor code (không change logic)
- **ci**: CI/CD changes
- **chore**: Dependencies, configs

### Scope (phần code bị ảnh hưởng):
- `frontend` / `backend`
- `auth` / `event` / `approval` / `saved`
- `api` / `ui` / `database`

### Examples:

```bash
# Good commits:
git commit -m "feat(event): add save/unsave event functionality"
git commit -m "fix(approval): handle null approval_id correctly"
git commit -m "test(frontend): add widget tests for event detail screen"
git commit -m "docs(api): update event endpoints documentation"
git commit -m "ci(github-actions): setup automated testing pipeline"

# Avoid:
git commit -m "fix stuff"
git commit -m "update"
git commit -m "WIP"
```

---

## 🔄 Workflow: Create & Merge Feature

### 1️⃣ Start feature branch:
```bash
# Update develop branch
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/your-feature-name
```

### 2️⃣ Make changes & commit:
```bash
# Make code changes
git add .
git commit -m "feat(scope): description"
git commit -m "test(scope): add tests"

# Keep updated with develop
git fetch origin
git rebase origin/develop
```

### 3️⃣ Push & Create PR:
```bash
git push origin feature/your-feature-name
```

Then on GitHub: **Create Pull Request**

### 4️⃣ Review & Merge:
- At least 1 team member reviews
- All CI/tests must pass (GitHub Actions)
- Merge to `develop` (not directly to `main`)

### 5️⃣ Cleanup:
```bash
git checkout develop
git pull origin develop
git branch -d feature/your-feature-name
```

---

## ✅ Pull Request Checklist

Before pushing feature branch:

- [ ] Code changes follow project style
- [ ] Tests added/updated
- [ ] `make ci-test-local` passes
- [ ] No merge conflicts with develop
- [ ] Commit messages are clear
- [ ] Documentation updated (if needed)
- [ ] No debugging code (print, TODO comments)

### PR Title Format:
```
[Frontend/Backend/Test] Brief description

Example:
[Frontend] Add event detail screen with participant counts
[Backend] Fix approval status mapping bug
[Test] Setup GitHub Actions CI pipeline
```

### PR Description Template:
```markdown
## Changes
- What was changed and why?
- Which features does this affect?

## Testing
- How was this tested?
- Test cases covered:
  - [ ] Feature works on happy path
  - [ ] Error handling works
  - [ ] No regression on existing features

## Screenshots (if UI change)
[Attach images]

## Related Issues
Fixes #123
```

---

## 🚀 Deployment Flow

### Development → Testing → Production

```
Feature Branch
     ↓
  develop (testing branch)
     ↓
  (QA/review)
     ↓
  main (production)
```

### Tags for releases:
```bash
# After merging to main
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

---

## 📊 Common Scenarios

### Scenario 1: Reviewing someone's code
```bash
# Check out their branch
git checkout feature/their-feature
git pull origin feature/their-feature

# Test locally
flutter test test/frontend_test_suite.dart

# Review on GitHub (leave comments)
# Approve or request changes
```

### Scenario 2: Fix conflict in PR
```bash
git checkout feature/your-feature
git fetch origin
git rebase origin/develop

# Resolve conflicts in editor
git add .
git rebase --continue
git push origin feature/your-feature -f
```

### Scenario 3: Oops, wrong branch
```bash
# Create backup
git branch feature/backup

# Reset to correct state
git checkout develop
git checkout -b feature/correct-name
```

### Scenario 4: Urgent bug in production
```bash
# Create hotfix from main
git checkout main
git checkout -b hotfix/urgent-bug
# Make fix
git add .
git commit -m "fix(critical): urgent bug fix"
git push origin hotfix/urgent-bug

# Create PR to main (fast track)
# After merge to main, also merge to develop
```

---

## 📈 Team Communication

### Status update (daily/weekly):
```bash
# See who did what
git log --oneline --graph --decorate --all

# See commits by person
git shortlog -sn

# See what changed this week
git log --since="1 week ago" --oneline
```

### Sync with team:
```bash
# Before starting work
git fetch origin
git rebase origin/develop

# After team members push
git pull origin develop
```

---

## 🔐 Best Practices

### DO:
✅ Commit often (small, logical chunks)  
✅ Write descriptive commit messages  
✅ Pull before push  
✅ Test before committing  
✅ Review code before merging  
✅ Use branches for everything  

### DON'T:
❌ Commit directly to main or develop  
❌ Force push to shared branches  
❌ Mix multiple features in one commit  
❌ Commit without running tests  
❌ Leave broken code in commits  
❌ Commit .env, secrets, or credentials  

---

## 🔒 .gitignore

Make sure these are ignored:

```
# Environment
.env
.env.local
.env.*.local

# Frontend
build/
.dart_tool/
pubspec.lock (usually committed, but check)

# Backend
venv/
__pycache__/
*.pyc
db.sqlite3
test_db.sqlite3
.coverage

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store
Thumbs.db
```

---

## 📞 Questions?

- **Merge conflicts?** → `git status` to see conflicts, resolve in editor
- **Lost commits?** → `git reflog` to recover
- **Need history?** → `git log --oneline | head -20`
- **Undo last commit?** → `git reset HEAD~1`

---

## 🎯 Sample Weekly Workflow

**Monday:**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/my-feature
# Code...
```

**Wednesday:**
```bash
git add .
git commit -m "feat(event): add new feature"
git push origin feature/my-feature
# Create PR on GitHub
```

**Friday:**
```bash
# Code review + merge on GitHub
git checkout develop
git pull origin develop
git branch -d feature/my-feature
```

---

## ✨ Tips

- Use `git branch -a` to see all branches
- Use `git status` frequently
- Use descriptive branch names (team will understand instantly)
- Small PRs = faster review = faster merge
- Auto-squash commits before merge: `git rebase -i develop`
