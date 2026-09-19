import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import { dirname } from 'node:path';

const EMPTY_STATE = () => ({
  version: 2,
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

  async apply({ deviceId, cursor, limit, mutations, protocolVersion = 1 }) {
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
        const incomingIsDeleted = incoming.entry.isDeleted === true;
        const currentIsDeleted = current?.entry?.isDeleted === true;
        const accepted = !current || incomingIsDeleted ||
          (!currentIsDeleted && compareVersions(incoming, current) > 0);

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
            sequence: change.sequence,
          };
          this.state.changes.push(change);
          this.state.mutations[mutation.mutationId] = {
            sequence: change.sequence,
            entryId: mutation.entry.id,
            accepted: true,
          };
          appliedMutationIds.push(mutation.mutationId);
        } else {
          let conflictId = null;
          if (protocolVersion >= 2) {
            conflictId = `conflict:${mutation.entry.id}:${mutation.mutationId}`;
            if (!this.state.entries[conflictId]) {
              const conflictEntry = {
                ...clone(mutation.entry),
                id: conflictId,
                schemaVersion: 2,
                isConflict: true,
                conflictOf: mutation.entry.id,
                conflictStatus: 'pending',
              };
              this.state.sequence += 1;
              const conflictChange = {
                sequence: this.state.sequence,
                mutationId: conflictId,
                deviceId,
                entry: clone(conflictEntry),
              };
              this.state.entries[conflictId] = {
                mutationId: conflictId,
                entry: clone(conflictEntry),
                deviceId,
                sequence: conflictChange.sequence,
              };
              this.state.changes.push(conflictChange);
              this.state.mutations[conflictId] = {
                sequence: conflictChange.sequence,
                entryId: conflictId,
                accepted: true,
                conflictOf: mutation.entry.id,
              };
            }
            appliedMutationIds.push(mutation.mutationId);
          }
          this.state.mutations[mutation.mutationId] = {
            sequence: current.sequence ?? null,
            entryId: mutation.entry.id,
            accepted: false,
            conflictId,
          };
          conflicts.push({
            mutationId: mutation.mutationId,
            entryId: mutation.entry.id,
            conflictId,
            entry: conflictId ? clone(this.state.entries[conflictId].entry) : undefined,
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
