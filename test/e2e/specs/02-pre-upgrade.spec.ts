import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { rpc } from '../helpers/rpc'
import { UPLOAD_LIMIT } from '../helpers/upgrade'

test('upload speed limit before upgrade', async ({ page }) => {
  await loginViaAuthelia(page)
  await rpc(page, 'session-set', {
    'speed-limit-up-enabled': true,
    'speed-limit-up': Number(UPLOAD_LIMIT),
  })
  const session = await rpc(page, 'session-get')
  expect(session['speed-limit-up-enabled']).toBe(true)
  expect(String(session['speed-limit-up'])).toBe(UPLOAD_LIMIT)
  await shoot(page, 'main-before-upgrade')
})
