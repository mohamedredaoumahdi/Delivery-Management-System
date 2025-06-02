module.exports = {
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
  plugins: ['@typescript-eslint'],
  extends: [
    'eslint:recommended',
  ],
  env: {
    node: true,
    es2020: true,
    jest: true,
  },
  rules: {
    '@typescript-eslint/no-unused-vars': 'off',
    'no-unused-vars': 'off',
    'no-console': 'warn',
    'prefer-const': 'error',
    'no-var': 'error',
    'no-undef': 'off', // TypeScript handles this
  },
  overrides: [
    {
      files: ['**/config/database.ts'],
      rules: {
        'no-var': 'off', // Allow var in global declarations
      },
    },
    {
      files: ['**/utils/logger.ts'],
      rules: {
        'no-console': 'off', // Allow console in logger utility
      },
    },
  ],
  ignorePatterns: ['dist/', 'node_modules/', '*.js', 'prisma/'],
}; 