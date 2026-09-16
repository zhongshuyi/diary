const fs = require('node:fs');
const zlib = require('node:zlib');

const ZIP_LOCAL = 0x04034b50;
const ZIP_CENTRAL = 0x02014b50;
const ZIP_END = 0x06054b50;
const MAX_ARCHIVE_BYTES = 512 * 1024 * 1024;

const CRC_TABLE = new Uint32Array(256);
for (let index = 0; index < CRC_TABLE.length; index += 1) {
  let value = index;
  for (let bit = 0; bit < 8; bit += 1) value = value & 1 ? (value >>> 1) ^ 0xedb88320 : value >>> 1;
  CRC_TABLE[index] = value >>> 0;
}

function crc32(data) {
  let value = 0xffffffff;
  for (const byte of data) value = CRC_TABLE[(value ^ byte) & 0xff] ^ (value >>> 8);
  return (value ^ 0xffffffff) >>> 0;
}

function safeArchivePath(value) {
  const name = String(value || '').replace(/\\/g, '/');
  if (!name || name.startsWith('/') || /^[a-zA-Z]:/.test(name) || name.split('/').some((part) => part === '..' || part === '')) throw new Error('Invalid backup path');
  return name;
}

function dosDateTime(date = new Date()) {
  const year = Math.max(1980, date.getFullYear());
  return {
    time: (date.getHours() << 11) | (date.getMinutes() << 5) | Math.floor(date.getSeconds() / 2),
    date: ((year - 1980) << 9) | ((date.getMonth() + 1) << 5) | date.getDate(),
  };
}

function buildZip(files) {
  if (!Array.isArray(files) || files.length > 65535) throw new TypeError('Backup files are invalid');
  const localParts = [];
  const centralParts = [];
  let offset = 0;
  const seen = new Set();
  files.forEach((file) => {
    const name = safeArchivePath(file?.name);
    if (seen.has(name)) throw new Error(`Duplicate backup path: ${name}`);
    seen.add(name);
    const data = Buffer.isBuffer(file?.data) ? file.data : Buffer.from(file?.data ?? '');
    const nameBytes = Buffer.from(name, 'utf8');
    if (nameBytes.length > 0xffff || data.length > 0xffffffff) throw new Error('Backup file is too large');
    const checksum = crc32(data);
    const stamp = dosDateTime(file?.date ? new Date(file.date) : new Date());
    const local = Buffer.alloc(30 + nameBytes.length);
    local.writeUInt32LE(ZIP_LOCAL, 0);
    local.writeUInt16LE(20, 4);
    local.writeUInt16LE(0x800, 6);
    local.writeUInt16LE(0, 8);
    local.writeUInt16LE(stamp.time, 10);
    local.writeUInt16LE(stamp.date, 12);
    local.writeUInt32LE(checksum, 14);
    local.writeUInt32LE(data.length, 18);
    local.writeUInt32LE(data.length, 22);
    local.writeUInt16LE(nameBytes.length, 26);
    local.writeUInt16LE(0, 28);
    nameBytes.copy(local, 30);
    localParts.push(local, data);

    const central = Buffer.alloc(46 + nameBytes.length);
    central.writeUInt32LE(ZIP_CENTRAL, 0);
    central.writeUInt16LE(20, 4);
    central.writeUInt16LE(20, 6);
    central.writeUInt16LE(0x800, 8);
    central.writeUInt16LE(0, 10);
    central.writeUInt16LE(stamp.time, 12);
    central.writeUInt16LE(stamp.date, 14);
    central.writeUInt32LE(checksum, 16);
    central.writeUInt32LE(data.length, 20);
    central.writeUInt32LE(data.length, 24);
    central.writeUInt16LE(nameBytes.length, 28);
    central.writeUInt16LE(0, 30);
    central.writeUInt16LE(0, 32);
    central.writeUInt16LE(0, 34);
    central.writeUInt16LE(0, 36);
    central.writeUInt32LE(0, 38);
    central.writeUInt32LE(offset, 42);
    nameBytes.copy(central, 46);
    centralParts.push(central);
    offset += local.length + data.length;
  });

  const centralOffset = offset;
  const centralData = Buffer.concat(centralParts);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(ZIP_END, 0);
  end.writeUInt16LE(0, 4);
  end.writeUInt16LE(0, 6);
  end.writeUInt16LE(centralParts.length, 8);
  end.writeUInt16LE(centralParts.length, 10);
  end.writeUInt32LE(centralData.length, 12);
  end.writeUInt32LE(centralOffset, 16);
  end.writeUInt16LE(0, 20);
  const archive = Buffer.concat([...localParts, centralData, end]);
  if (archive.length > MAX_ARCHIVE_BYTES) throw new Error('Backup archive is too large');
  return archive;
}

function readZip(archive) {
  if (!Buffer.isBuffer(archive) || archive.length > MAX_ARCHIVE_BYTES) throw new Error('Invalid backup archive');
  const minimumOffset = Math.max(0, archive.length - 0xffff - 22);
  const endOffset = archive.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]), archive.length - 22);
  if (endOffset < minimumOffset) throw new Error('Backup archive is truncated');
  const count = archive.readUInt16LE(endOffset + 10);
  const centralSize = archive.readUInt32LE(endOffset + 12);
  const centralOffset = archive.readUInt32LE(endOffset + 16);
  if (centralOffset + centralSize > endOffset || count > 65535) throw new Error('Backup archive directory is invalid');
  const files = new Map();
  let cursor = centralOffset;
  let totalUncompressed = 0;
  for (let index = 0; index < count; index += 1) {
    if (cursor + 46 > archive.length || archive.readUInt32LE(cursor) !== ZIP_CENTRAL) throw new Error('Backup archive entry is invalid');
    const flags = archive.readUInt16LE(cursor + 8);
    const method = archive.readUInt16LE(cursor + 10);
    const checksum = archive.readUInt32LE(cursor + 16);
    const compressedSize = archive.readUInt32LE(cursor + 20);
    const uncompressedSize = archive.readUInt32LE(cursor + 24);
    const nameLength = archive.readUInt16LE(cursor + 28);
    const extraLength = archive.readUInt16LE(cursor + 30);
    const commentLength = archive.readUInt16LE(cursor + 32);
    const localOffset = archive.readUInt32LE(cursor + 42);
    const nameBytes = archive.subarray(cursor + 46, cursor + 46 + nameLength);
    const name = safeArchivePath(nameBytes.toString(flags & 0x800 ? 'utf8' : 'utf8'));
    if (files.has(name) || cursor + 46 + nameLength + extraLength + commentLength > archive.length) throw new Error('Backup archive entry name is invalid');
    if (localOffset + 30 > archive.length || archive.readUInt32LE(localOffset) !== ZIP_LOCAL) throw new Error('Backup archive local header is invalid');
    const localNameLength = archive.readUInt16LE(localOffset + 26);
    const localExtraLength = archive.readUInt16LE(localOffset + 28);
    const dataStart = localOffset + 30 + localNameLength + localExtraLength;
    const dataEnd = dataStart + compressedSize;
    totalUncompressed += uncompressedSize;
    if (dataEnd > archive.length || uncompressedSize > MAX_ARCHIVE_BYTES || totalUncompressed > MAX_ARCHIVE_BYTES) throw new Error('Backup archive data is invalid');
    const compressed = archive.subarray(dataStart, dataEnd);
    let data;
    if (method === 0) data = Buffer.from(compressed);
    else if (method === 8) data = zlib.inflateRawSync(compressed);
    else throw new Error('Backup compression method is not supported');
    if (data.length !== uncompressedSize || crc32(data) !== checksum) throw new Error(`Backup checksum mismatch: ${name}`);
    files.set(name, data);
    cursor += 46 + nameLength + extraLength + commentLength;
  }
  return files;
}

function writeZipFile(filePath, files) {
  const archive = buildZip(files);
  fs.writeFileSync(filePath, archive);
  return { path: filePath, bytes: archive.length };
}

function readZipFile(filePath) {
  return readZip(fs.readFileSync(filePath));
}

module.exports = { buildZip, readZip, writeZipFile, readZipFile, safeArchivePath };
