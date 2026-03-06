# Contributing

## Branching

- Use short-lived feature branches from `master`.
- Keep pull requests focused and small.

## Commit Convention

- `feat:` for new functionality
- `fix:` for bug fixes
- `chore:` for tooling, scripts, maintenance
- `docs:` for documentation updates
- `ci:` for CI/CD changes

## Local Development

1. Start dependencies:
   - `.\start-all.cmd -NoBackend -SkipDbImport -SkipBuild`
2. Run backend:
   - `.\mvnw.cmd spring-boot:run`
3. Validate:
   - `.\mvnw.cmd -q -DskipTests compile`
   - `curl http://localhost:8088/api/v1/actuator/health`

## Pull Request Checklist

- Build passes locally.
- No local runtime artifacts are committed.
- README is updated if behavior or setup changed.
- Changes are backward compatible or clearly documented.
