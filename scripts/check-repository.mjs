import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const requiredDocuments = ['LICENSE', 'PRIVACY.md', 'THIRD_PARTY_NOTICES.md'];
const packageFiles = ['desktop/package.json', 'server/package.json'];

function normalizePath(value) {
  if (typeof value !== 'string' || !value || /[\u0000-\u001f\u007f]/u.test(value)) return null;
  const path = value.replaceAll('\\', '/');
  if (path.startsWith('/') || /^[a-z]:/iu.test(path)) return null;
  const segments = path.split('/');
  if (segments.includes('..')) return null;
  return segments.filter(segment => segment && segment !== '.').join('/') || null;
}

/** Check names only: this function never opens a tracked file. */
export function checkTrackedPaths(paths) {
  return paths.flatMap(path => {
    const normalized = normalizePath(path);
    if (!normalized) return [{ path, rule: 'invalid-repository-path' }];
    const lower = normalized.toLowerCase();
    const segments = lower.split('/');
    const name = segments.at(-1);
    let rule;
    if (segments.some(segment => ['.local', 'node_modules', '.dart_tool'].includes(segment))) {
      rule = 'private-or-generated-directory';
    } else if (/^(?:mobile\/build|desktop\/(?:dist|release|release-final))(?:\/|$)/u.test(lower)) {
      rule = 'build-output';
    } else if (lower.startsWith('server/data/') && lower !== 'server/data/.gitkeep') {
      rule = 'personal-data';
    } else if (name === 'key.properties' || /\.(?:jks|keystore|p12|pfx)$/u.test(name)) {
      rule = 'private-signing-material';
    } else if ((name === '.env' || name.startsWith('.env.')) && name !== '.env.example') {
      rule = 'private-environment-file';
    } else if (/\.(?:db|sqlite|sqlite3|isar)(?:-(?:wal|shm))?$/u.test(name)) {
      rule = 'personal-database';
    } else if (/\.(?:apk|aab|exe|msi|dmg|asar)$/u.test(name)) {
      rule = 'built-installer';
    }
    return rule ? [{ path, rule }] : [];
  });
}

function pinnedAction(reference) {
  if (reference.startsWith('./')) return normalizePath(reference) !== null;
  if (reference.startsWith('docker://')) return /@sha256:[a-f\d]{64}$/iu.test(reference);
  const [repository, revision, extra] = reference.split('@');
  return !extra && /^[a-f\d]{40}$/iu.test(revision ?? '')
    && /^[\w.-]+\/[\w.-]+(?:\/[\w./-]+)?$/u.test(repository)
    && !repository.split('/').includes('..');
}

/** Parse only uses: lines; no dependency or full YAML parser is needed. */
export function checkWorkflowActions(path, source) {
  return source.split(/\r?\n/u).flatMap((line, index) => {
    const match = /^\s*(?:-\s*)?uses:\s*(.*?)\s*$/u.exec(line);
    if (!match) return [];
    let reference = match[1].replace(/\s+#.*$/u, '');
    if (/^(['"]).*\1$/u.test(reference)) reference = reference.slice(1, -1);
    return pinnedAction(reference) ? [] : [{ path, rule: 'unpinned-action', line: index + 1 }];
  });
}

/** Validate public metadata supplied by the caller, without filesystem access. */
export function checkMetadata({ files = [], packages = {} } = {}) {
  const present = new Set(files);
  return [
    ...requiredDocuments.filter(path => !present.has(path))
      .map(path => ({ path, rule: 'missing-public-document' })),
    ...packageFiles.filter(path => packages[path]?.license !== 'MIT')
      .map(path => ({ path, rule: 'project-license-must-be-MIT' })),
  ];
}

function isActionYaml(path) {
  return (path.startsWith('.github/workflows/') && /\.ya?ml$/iu.test(path))
    || /(?:^|\/)action\.ya?ml$/iu.test(path);
}

function main() {
  const root = resolve(import.meta.dirname, '..');
  const paths = execFileSync('git', ['ls-files', '-z'], {
    cwd: root, encoding: 'utf8', maxBuffer: 8 * 1024 * 1024,
  }).split('\0').filter(Boolean);
  const violations = checkTrackedPaths(paths);
  // Fail before content reads when any private/generated path is tracked.
  if (!violations.length) {
    const packages = {};
    for (const path of packageFiles) {
      try {
        packages[path] = JSON.parse(readFileSync(join(root, path), 'utf8'));
      } catch {
        violations.push({ path, rule: 'invalid-public-package-json' });
      }
    }
    violations.push(...checkMetadata({
      files: requiredDocuments.filter(path => existsSync(join(root, path))), packages,
    }));
    for (const path of paths.filter(isActionYaml)) {
      violations.push(...checkWorkflowActions(path, readFileSync(join(root, path), 'utf8')));
    }
  }
  if (violations.length) {
    console.error('Repository policy violations:');
    for (const issue of violations) {
      console.error(`- ${JSON.stringify(issue.path)}${issue.line ? `:${issue.line}` : ''}: ${issue.rule}`);
    }
    process.exitCode = 1;
  } else {
    console.log(`Repository checks passed (${paths.length} tracked paths).`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try {
    main();
  } catch {
    console.error('Repository check could not complete; verify Git and public metadata are readable.');
    process.exitCode = 1;
  }
}
