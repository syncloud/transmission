import { ssh, scpFrom } from './helpers/ssh'
import * as path from 'node:path'
import * as fs from 'node:fs'
import { execSync } from 'node:child_process'

const TMP_DIR = '/tmp/syncloud/transmission-ui'
const artifactRoot = process.env.PLAYWRIGHT_ARTIFACT_DIR ?? 'artifact'

export default async function () {
  const project = process.env.PLAYWRIGHT_PROJECT ?? 'desktop'
  const out = path.join(artifactRoot, 'playwright', project)
  fs.mkdirSync(out, { recursive: true })

  ssh(`mkdir -p ${TMP_DIR}`, { throw: false })
  ssh(`journalctl > ${TMP_DIR}/journalctl.log`, { throw: false })
  ssh(`ls -la /var/snap/transmission/current/config > ${TMP_DIR}/config.ls.log 2>&1`, { throw: false })
  ssh(`cat /var/snap/transmission/current/config/transmission/settings.json > ${TMP_DIR}/settings.json 2>&1`, { throw: false })
  scpFrom(`${TMP_DIR}/*`, out, { throw: false })
  try { execSync(`chmod -R a+r ${out}`) } catch {}
}
