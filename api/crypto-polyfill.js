import { webcrypto } from 'node:crypto';

// Node 18 (Windows 8.1) does not expose the WebCrypto global by default - it
// became default-on in Node 19. @simplewebauthn/server expects globalThis.crypto.
// Polyfill it (no-op on Node 19+) so the API works on both.
if (typeof globalThis.crypto === 'undefined') {
    globalThis.crypto = webcrypto;
}
