import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['tests/unit/**/*.test.ts'],
    // tests/fixtures/ holds sample projects that the harness-init regression drivers
    // overlay templates onto. Their *.test.ts files are fixture DATA, not this
    // repository's tests, and must never be collected.
    exclude: ['tests/fixtures/**', 'node_modules/**'],
  },
});
