yarn build
yarn run v1.22.22
$ next build
   ▲ Next.js 16.0.10 (Turbopack)
   - Environments: .env

   Creating an optimized production build ...
(node:150846) ExperimentalWarning: Type Stripping is an experimental feature and might change at any time
(Use `node --trace-warnings ...` to show where the warning was created)

> Build error occurred
Error: Turbopack build failed with 71 errors:
./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/ts.test.ts
Missing module type
The module type effect must be applied before adding Ecmascript transforms


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/ts/to-file.ts
Missing module type
The module type effect must be applied before adding Ecmascript transforms


./node_modules/thread-stream/test/ts.test.ts
Missing module type
The module type effect must be applied before adding Ecmascript transforms


./node_modules/thread-stream/test/ts/to-file.ts
Missing module type
The module type effect must be applied before adding Ecmascript transforms


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/README.md
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/dir with spaces/test-package.zip
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/ts-commonjs-default-export.zip
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/ts.test.ts
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/ts/to-file.ts
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/ts/transpile.sh
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/yarnrc.yml
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/thread-stream/README.md
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/thread-stream/test/dir with spaces/test-package.zip
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/thread-stream/test/ts.test.ts
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/thread-stream/test/ts/to-file.ts
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/thread-stream/test/ts/transpile.sh
Unknown module type
This module doesn't have an associated type. Use a known file extension, or register a loader for it.

Read more: https://nextjs.org/docs/app/api-reference/next-config-js/turbo#webpack-loaders


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/LICENSE:1:5
Parsing ecmascript source code failed
> 1 | MIT License
    |     ^^^^^^^
  2 |
  3 | Copyright (c) 2021 Matteo Collina
  4 |

Expected ';', '}' or <eof>

Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/LICENSE [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/syntax-error.mjs:2:7
Parsing ecmascript source code failed
  1 | // this is a syntax error
> 2 | import
    |       ^
  3 |

Expected 'from', got '<eof>'

Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/syntax-error.mjs [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]


./node_modules/thread-stream/LICENSE:1:5
Parsing ecmascript source code failed
> 1 | MIT License
    |     ^^^^^^^
  2 |
  3 | Copyright (c) 2021 Matteo Collina
  4 |

Expected ';', '}' or <eof>

Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/LICENSE [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]


./app/SectionDeployDemo.tsx:75:37
Module not found: Can't resolve '../../solidity/powered/' <dynamic> '.json'
  73 |
  74 |   const getPowered = useCallback(async (chainId: number) => {
> 75 |     const { default: data } = await import(`../../solidity/powered/${chainId}.json`, { assert: { type: "json" } });
     |                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  76 |     setBytecodePowers(data.powers as `0x${string}`);
  77 |     setDeployedMandates(data.mandates as Record<string, `0x${string}`>);
  78 |   }, []);



Import traces:
  Client Component Browser:
    ./app/SectionDeployDemo.tsx [Client Component Browser]
    ./app/page.tsx [Client Component Browser]
    ./app/page.tsx [Server Component]

  Client Component SSR:
    ./app/SectionDeployDemo.tsx [Client Component SSR]
    ./app/page.tsx [Client Component SSR]
    ./app/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test
Module not found: Can't resolve './ROOT/node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/close-on-gc.js'
server relative imports are not implemented yet. Please try an import relative to the file you are importing from.


https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test
Module not found: Can't resolve './ROOT/node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/create-and-exit.js'
server relative imports are not implemented yet. Please try an import relative to the file you are importing from.


https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test
Module not found: Can't resolve './ROOT/node_modules/thread-stream/test/close-on-gc.js'
server relative imports are not implemented yet. Please try an import relative to the file you are importing from.


https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test
Module not found: Can't resolve './ROOT/node_modules/thread-stream/test/create-and-exit.js'
server relative imports are not implemented yet. Please try an import relative to the file you are importing from.


https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/thread-management.test.js:112:17
Module not found: Can't resolve '/ROOT/node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/close-on-gc.js'
  110 | test('close the work if out of scope on gc', { skip: !global.WeakRef }, async function (t) {
  111 |   const dest = file()
> 112 |   const child = fork(join(__dirname, 'close-on-gc.js'), [dest], {
      |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
> 113 |     execArgv: ['--expose-gc']
      | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
> 114 |   })
      | ^^^^^
  115 |
  116 |   const [code] = await once(child, 'exit')
  117 |   t.equal(code, 0)



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/thread-management.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/thread-management.test.js:13:17
Module not found: Can't resolve '/ROOT/node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/create-and-exit.js'
  11 | test('exits with 0', async function (t) {
  12 |   const dest = file()
> 13 |   const child = fork(join(__dirname, 'create-and-exit.js'), [dest])
     |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  14 |
  15 |   const [code] = await once(child, 'exit')
  16 |   t.equal(code, 0)



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/thread-management.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/thread-management.test.js:164:17
Module not found: Can't resolve '/ROOT/node_modules/thread-stream/test/close-on-gc.js'
  162 | test('close the work if out of scope on gc', { skip: !global.WeakRef }, async function (t) {
  163 |   const dest = file()
> 164 |   const child = fork(join(__dirname, 'close-on-gc.js'), [dest], {
      |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
> 165 |     execArgv: ['--expose-gc']
      | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
> 166 |   })
      | ^^^^^
  167 |
  168 |   const [code] = await once(child, 'exit')
  169 |   t.equal(code, 0)



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/thread-management.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/thread-management.test.js:13:17
Module not found: Can't resolve '/ROOT/node_modules/thread-stream/test/create-and-exit.js'
  11 | test('exits with 0', async function (t) {
  12 |   const dest = file()
> 13 |   const child = fork(join(__dirname, 'create-and-exit.js'), [dest])
     |                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  14 |
  15 |   const [code] = await once(child, 'exit')
  16 |   t.equal(code, 0)



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/thread-management.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/esm.test.mjs:4:1
Module not found: Can't resolve 'desm'
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
> 4 | import { join } from 'desm'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  5 | import { pathToFileURL } from 'url'
  6 | import { file } from './helper.js'
  7 |



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/esm.test.mjs [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/multibyte-chars.test.mjs:4:1
Module not found: Can't resolve 'desm'
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
> 4 | import { join } from 'desm'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  5 | import { file } from './helper.js'
  6 |
  7 | test('break up utf8 multibyte (sync)', (t) => {



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/multibyte-chars.test.mjs [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/esm.test.mjs:4:1
Module not found: Can't resolve 'desm'
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
> 4 | import { join } from 'desm'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  5 | import { pathToFileURL } from 'url'
  6 | import { file } from './helper.js'
  7 |



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/esm.test.mjs [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/multibyte-chars.test.mjs:4:1
Module not found: Can't resolve 'desm'
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
> 4 | import { join } from 'desm'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^
  5 | import { file } from './helper.js'
  6 |
  7 | test('break up utf8 multibyte (sync)', (t) => {



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/multibyte-chars.test.mjs [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/bench.js:3:15
Module not found: Can't resolve 'fastbench'
  1 | 'use strict'
  2 |
> 3 | const bench = require('fastbench')
    |               ^^^^^^^^^^^^^^^^^^^^
  4 | const SonicBoom = require('sonic-boom')
  5 | const ThreadStream = require('.')
  6 | const Console = require('console').Console



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/bench.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/bench.js:3:15
Module not found: Can't resolve 'fastbench'
  1 | 'use strict'
  2 |
> 3 | const bench = require('fastbench')
    |               ^^^^^^^^^^^^^^^^^^^^
  4 | const SonicBoom = require('sonic-boom')
  5 | const ThreadStream = require('.')
  6 | const Console = require('console').Console



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/bench.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/commonjs-fallback.test.js:14:22
Module not found: Can't resolve 'pino-elasticsearch'
  12 |   t.plan(6)
  13 |
> 14 |   const modulePath = require.resolve('pino-elasticsearch')
     |                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  15 |   t.match(modulePath, /.*\.zip.*/)
  16 |
  17 |   const stream = new ThreadStream({



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/commonjs-fallback.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/commonjs-fallback.test.js:14:22
Module not found: Can't resolve 'pino-elasticsearch'
  12 |   t.plan(6)
  13 |
> 14 |   const modulePath = require.resolve('pino-elasticsearch')
     |                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  15 |   t.match(modulePath, /.*\.zip.*/)
  16 |
  17 |   const stream = new ThreadStream({



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/commonjs-fallback.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/base.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { readFile } = require('fs')
  6 | const { file } = require('./helper')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/base.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/bench.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const ThreadStream = require('..')
  6 | const { file } = require('./helper')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/bench.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/bundlers.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { file } = require('./helper')
  6 | const ThreadStream = require('..')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/bundlers.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/commonjs-fallback.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { MessageChannel } = require('worker_threads')
  6 | const { once } = require('events')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/commonjs-fallback.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/context.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const ThreadStream = require('..')
  6 | const { version } = require('../package.json')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/context.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/end.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { readFile } = require('fs')
  6 | const { file } = require('./helper')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/end.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/esm.test.mjs:1:1
Module not found: Can't resolve 'tap'
> 1 | import { test } from 'tap'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
  4 | import { join } from 'desm'



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/esm.test.mjs [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/event.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const ThreadStream = require('..')
  6 |



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/event.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/helper.js:6:11
Module not found: Can't resolve 'tap'
  4 | const { tmpdir } = require('os')
  5 | const { unlinkSync } = require('fs')
> 6 | const t = require('tap')
    |           ^^^^^^^^^^^^^^
  7 |
  8 | const files = []
  9 | let count = 0



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/helper.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/indexes.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const indexes = require('../lib/indexes')
  5 |
  6 | for (const index of Object.keys(indexes)) {



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/indexes.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/multibyte-chars.test.mjs:1:1
Module not found: Can't resolve 'tap'
> 1 | import { test } from 'tap'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
  4 | import { join } from 'desm'



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/multibyte-chars.test.mjs [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/never-drain.test.js:1:18
Module not found: Can't resolve 'tap'
> 1 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  2 | const ThreadStream = require('../index')
  3 | const { join } = require('path')
  4 |



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/never-drain.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/pkg/index.js:7:18
Module not found: Can't resolve 'tap'
   5 |  */
   6 |
>  7 | const { test } = require('tap')
     |                  ^^^^^^^^^^^^^^
   8 | const { join } = require('path')
   9 | const { file } = require('../helper')
  10 | const ThreadStream = require('../..')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/pkg/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/pkg/pkg.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const config = require('./pkg.config.json')
  5 | const { promisify } = require('util')
  6 | const { unlink } = require('fs/promises')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/pkg/pkg.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/post-message.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { once } = require('events')
  6 | const { MessageChannel } = require('worker_threads')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/post-message.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/string-limit-2.test.js:3:11
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const t = require('tap')
    |           ^^^^^^^^^^^^^^
  4 |
  5 | if (process.env.CI) {
  6 |   t.skip('skip on CI')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/string-limit-2.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/string-limit.test.js:3:11
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const t = require('tap')
    |           ^^^^^^^^^^^^^^
  4 |
  5 | if (process.env.CI) {
  6 |   t.skip('skip on CI')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/string-limit.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/thread-management.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { fork } = require('child_process')
  5 | const { join } = require('path')
  6 | const { readFile } = require('fs').promises



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/thread-management.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/transpiled.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { file } = require('./helper')
  6 | const ThreadStream = require('..')



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/transpiled.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/base.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { readFile } = require('fs')
  6 | const { file } = require('./helper')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/base.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/bench.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const ThreadStream = require('..')
  6 | const { file } = require('./helper')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/bench.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/bundlers.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { file } = require('./helper')
  6 | const ThreadStream = require('..')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/bundlers.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/commonjs-fallback.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { MessageChannel } = require('worker_threads')
  6 | const { once } = require('events')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/commonjs-fallback.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/end.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { readFile } = require('fs')
  6 | const { file } = require('./helper')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/end.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/esm.test.mjs:1:1
Module not found: Can't resolve 'tap'
> 1 | import { test } from 'tap'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
  4 | import { join } from 'desm'



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/esm.test.mjs [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/helper.js:7:11
Module not found: Can't resolve 'tap'
   5 | const { unlinkSync } = require('fs')
   6 | const why = require('why-is-node-running')
>  7 | const t = require('tap')
     |           ^^^^^^^^^^^^^^
   8 |
   9 | const files = []
  10 | let count = 0



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/helper.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/multibyte-chars.test.mjs:1:1
Module not found: Can't resolve 'tap'
> 1 | import { test } from 'tap'
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^
  2 | import { readFile } from 'fs'
  3 | import ThreadStream from '../index.js'
  4 | import { join } from 'desm'



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/multibyte-chars.test.mjs [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/string-limit-2.test.js:3:11
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const t = require('tap')
    |           ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { file } = require('./helper')
  6 | const { createReadStream } = require('fs')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/string-limit-2.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/string-limit.test.js:3:11
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const t = require('tap')
    |           ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { file } = require('./helper')
  6 | const { stat } = require('fs')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/string-limit.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/thread-management.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { fork } = require('child_process')
  5 | const { join } = require('path')
  6 | const { readFile } = require('fs').promises



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/thread-management.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/transpiled.test.js:3:18
Module not found: Can't resolve 'tap'
  1 | 'use strict'
  2 |
> 3 | const { test } = require('tap')
    |                  ^^^^^^^^^^^^^^
  4 | const { join } = require('path')
  5 | const { file } = require('./helper')
  6 | const ThreadStream = require('..')



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/transpiled.test.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/indexes.js:3:14
Module not found: Can't resolve 'tape'
  1 | 'use strict'
  2 |
> 3 | const test = require('tape')
    |              ^^^^^^^^^^^^^^^
  4 | const indexes = require('../lib/indexes')
  5 |
  6 | for (const index of Object.keys(indexes)) {



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/indexes.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/context.test.js:7:1
Module not found: Can't resolve 'why-is-node-running'
   5 | const ThreadStream = require('..')
   6 | const { version } = require('../package.json')
>  7 | require('why-is-node-running')
     | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   8 |
   9 | test('get context', (t) => {
  10 |   const stream = new ThreadStream({



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/context.test.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/helper.js:33:15
Module not found: Can't resolve 'why-is-node-running'
  31 |
  32 | if (process.env.SKIP_PROCESS_EXIT_CHECK !== 'true') {
> 33 |   const why = require('why-is-node-running')
     |               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  34 |   setInterval(why, 10000).unref()
  35 | }
  36 |



Import trace:
  Client Component SSR:
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/test/helper.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/logger/dist/index.es.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/node_modules/@walletconnect/utils/dist/index.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


./node_modules/thread-stream/test/helper.js:6:13
Module not found: Can't resolve 'why-is-node-running'
  4 | const { tmpdir } = require('os')
  5 | const { unlinkSync } = require('fs')
> 6 | const why = require('why-is-node-running')
    |             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  7 | const t = require('tap')
  8 |
  9 | const files = []



Import trace:
  Client Component SSR:
    ./node_modules/thread-stream/test/helper.js [Client Component SSR]
    ./node_modules/thread-stream/index.js [Client Component SSR]
    ./node_modules/pino/lib/transport.js [Client Component SSR]
    ./node_modules/pino/pino.js [Client Component SSR]
    ./node_modules/@reown/appkit/node_modules/@walletconnect/universal-provider/dist/index.es.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-base-client.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/src/client/appkit-core.js [Client Component SSR]
    ./node_modules/@reown/appkit/dist/esm/exports/core.js [Client Component SSR]
    ./node_modules/@walletconnect/ethereum-provider/dist/index.js [Client Component SSR]
    ./node_modules/@privy-io/react-auth/dist/esm/EmbeddedWalletConnectingScreen-DTl397rT.mjs [Client Component SSR]
    ./components/DynamicActionButton.tsx [Client Component SSR]
    ./components/MandateBox.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Client Component SSR]
    ./app/protocol/[chainId]/[powers]/mandates/[mandateId]/page.tsx [Server Component]

https://nextjs.org/docs/messages/module-not-found


    at <unknown> (./app/SectionDeployDemo.tsx:75:37)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
    at <unknown> (https://nextjs.org/docs/messages/module-not-found)
error Command failed with exit code 1.
info Visit https://yarnpkg.com/en/docs/cli/run for documentation about this command.
teijehidde@teijehidde-XPS-13-9360:~/Documents/7CedarsGit/projects/powers/frontend$ 
