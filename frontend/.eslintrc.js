module.exports = {
  root: true,
  extends: [
    'next/core-web-vitals',
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
  ],
  parser: '@typescript-eslint/parser',
  plugins: [
    '@typescript-eslint',
    'react',
  ],
  rules: {
    // TypeScript specific rules
    '@typescript-eslint/no-unused-vars': ['warn', { 
      argsIgnorePattern: '^_',
      varsIgnorePattern: '^_',
      caughtErrorsIgnorePattern: '^_'
    }],
    '@typescript-eslint/no-explicit-any': 'warn',
    '@typescript-eslint/explicit-function-return-type': 'off',
    '@typescript-eslint/explicit-module-boundary-types': 'off',
    '@typescript-eslint/no-non-null-assertion': 'warn',
    '@typescript-eslint/ban-types': 'warn',
    '@typescript-eslint/ban-ts-comment': 'warn',
    
    // React specific rules
    'react/react-in-jsx-scope': 'off', // Not needed in Next.js
    'react/prop-types': 'off', // Using TypeScript instead
    'react/display-name': 'off',
    'react/no-unescaped-entities': 'off',
    'react/no-unknown-property': 'off', // Allow custom properties like help-nav-item
    
    // React Hooks rules
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',
    
    // General rules
    'no-console': 'off', // Allow console statements
    'no-debugger': 'error',
    'prefer-const': 'warn',
    'no-var': 'error',
    'object-shorthand': 'warn',
    'prefer-template': 'warn',
    'no-undef': 'error',
    'no-empty': 'warn',
    'no-cond-assign': 'warn',
    'no-func-assign': 'error',
    'no-mixed-spaces-and-tabs': 'error',
    'no-case-declarations': 'warn',
    'no-sparse-arrays': 'warn',
    'no-useless-escape': 'warn',
    'valid-typeof': 'warn',
    
    // Next.js specific rules
    '@next/next/no-img-element': 'warn',
    
    // Accessibility rules (disabled for now)
    'jsx-a11y/role-supports-aria-props': 'off',
    'jsx-a11y/anchor-is-valid': 'off',
    'jsx-a11y/click-events-have-key-events': 'off',
    'jsx-a11y/no-static-element-interactions': 'off',
  },
  settings: {
    react: {
      version: 'detect',
    },
  },
  env: {
    browser: true,
    es2021: true,
    node: true,
    serviceworker: true, // For service worker files
  },
  parserOptions: {
    ecmaVersion: 2021,
    sourceType: 'module',
    ecmaFeatures: {
      jsx: true,
    },
  },
  ignorePatterns: [
    'node_modules/',
    '.next/',
    'out/',
    'build/',
    'dist/',
    '*.config.js',
    '*.config.mjs',
    'public/sw.js',
    'public/workbox-*.js',
    'public/orgMetadatas/',
    'public/roleThumbnails/',
    'app/source.js',
  ],
  globals: {
    // Service worker globals
    importScripts: 'readonly',
    define: 'readonly',
    registration: 'readonly',
    FetchEvent: 'readonly',
    // Other common globals
    _: 'readonly',
    // React and Node globals
    React: 'readonly',
    NodeJS: 'readonly',
  },
};
