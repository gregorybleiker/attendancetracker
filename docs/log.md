# Bundle Update Log

## 2026-10-13
* **Update**: The check-in kiosk now defaults to showing only a selected training's "regulars" (participants who have ever attended it), with a no-admin **Show all** toggle to reveal everyone. The admin participant listing gained a **Trainings** column, and the participant detail page a trainings table, showing which trainings each participant has attended. Documented in [Web layer](/architecture/web-layer.md) and [Elixir/Phoenix idioms](/architecture/idioms.md).

## 2026-10-03
* **Creation**: Established this OKF v0.2 bundle, migrating and splitting the former `ARCHITECTURE.md` into [Architecture](/architecture/index.md) concepts and `DEPLOY.md` into the operations concepts [Deployment](/deployment.md), [Backups](/backups.md), and [Troubleshooting](/troubleshooting.md).
* **Update**: Added `verified` events and code-level `sources` (relative paths into `lib/`, `priv/`, `test/`, and the deployment files) to every concept.
* **Update**: Added a pointer to this bundle in the repository-root `AGENTS.md`.
