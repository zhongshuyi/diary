import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

const EMPTY_STATE = () => ({
  version: 1,
  sequence: 0,
  entries: {},
  mutations: {},
  changes: [],
});

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function mutationKey({ entry, deviceId, mutationId }) {
  return [Date.parse(entry.updatedAt), deviceId, mutationId];
}

function compareVersions(left, right) {
  const leftKey = mutationKey(left);
  const rightKey = mutationKey(right);

  if (leftKey[0] !== rightKey[0]) return leftKey[0] - rightKey[0];
  if (leftKey[1] !== rightKey[1]) return leftKey[1].localeCompare(rightKey[1]);
  return leftKey[2].localeCompare(rightKey[2]);
}

export class SyncStore {
  constructor(filePath) {
    this.filePath = filePath;
    this.state = null;
    this.readyPromise = null;
    this.writeQueue = Promise.resolve();
  }

  async init() {
    if (this.readyPromise) return this.readyPromise;
    this.readyPromise = (async () => {
      try {
        const raw = await readFile(this.filePath, 'utf8');
        const parsed = JSON.parse(raw);
        this.state = {
          ...EMPTY_STATE(),
          ...parsed,
          entries: parsed.entries ?? {},
          mutations: parsed.mutations ?? {},
          changes: parsed.changes ?? [],
        };
      } catch (error) {
        if (error.code !== 'ENOENT') throw error;
        this.state = EMPTY_STATE();
        await this.persist();
      }
    })();
    return this.readyPromise;
  }

  async persist() {
    await mkdir(dirname(this.filePath), { recursive: true });
    const temporaryPath = `${this.filePath}.tmp`;
    await writeFile(temporaryPath, `${JSON.stringify(this.state, null, 2)}\n`, 'utf8');
    await rename(temporaryPath, this.filePath);
  }

  async apply({ deviceId, cursor, limit, mutations }) {
    await this.init();
    const operation = this.writeQueue.then(async () => {
      const appliedMutationIds = [];
      const conflicts = [];

      for (const mutation of mutations) {
        const existingMutation = this.state.mutations[mutation.mutationId];
        if (existingMutation) {
          appliedMutationIds.push(mutation.mutationId);
          continue;
        }

        const current = this.state.entries[mutation.entry.id];
        const incoming = { ...mutation, deviceId };
        const accepted = !current || compareVersions(incoming, current) > 0;

        if (accepted) {
          this.state.sequence += 1;
          const change = {
            sequence: this.state.sequence,
            mutationId: mutation.mutationId,
            deviceId,
            entry: clone(mutation.entry),
          };
          this.state.entries[mutation.entry.id] = {
            ...clone(mutation),
            deviceId,
          };
          this.state.changes.push(change);
          this.state.mutations[mutation.mutationId] = {
            sequence: change.sequence,
            entryId: mutation.entry.id,
            accepted: true,
          };
          appliedMutationIds.push(mutation.mutationId);
        } else {
          this.state.mutations[mutation.mutationId] = {
            sequence: current.sequence ?? null,
            entryId: mutation.entry.id,
            accepted: false,
          };
          conflicts.push({
            mutationId: mutation.mutationId,
            entryId: mutation.entry.id,
            serverEntry: clone(current.entry),
          });
        }
      }

      await this.persist();

      const afterSequence = Number(cursor || 0);
      const changes = this.state.changes
        .filter((change) => change.sequence > afterSequence)
        .slice(0, limit)
        .map(clone);
      const nextSequence = changes.length > 0
        ? changes[changes.length - 1].sequence
        : this.state.sequence;

      return {
        nextCursor: String(nextSequence),
        changes,
        appliedMutationIds,
        conflicts,
      };
    });

    this.writeQueue = operation.catch(() => undefined);
    return operation;
  }
}
