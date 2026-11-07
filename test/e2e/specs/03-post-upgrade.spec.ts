import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openSpeedPreferences } from '../helpers/nav'
import { UPLOAD_LIMIT } from '../helpers/upgrade'

test('upload speed limit survives upgrade', async ({ page }) => {
  await loginViaAuthelia(page)
  await shoot(page, 'main-after-upgrade')
  const { check, input } = await openSpeedPreferences(page)
  await expect(check).toBeChecked()
  await expect(input).toHaveValue(UPLOAD_LIMIT)
  await shoot(page, 'preferences-after-upgrade')
})
