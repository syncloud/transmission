import { test, expect } from '../fixtures'
import { shoot } from '../helpers/screenshot'
import { loginViaAuthelia } from '../helpers/auth'
import { openOverflowAction, openSpeedPreferences } from '../helpers/nav'

test('transmission', async ({ page }) => {
  await test.step('main', async () => {
    await loginViaAuthelia(page)
    await expect(page).toHaveTitle(/Transmission/i)
    await expect(page.locator('#torrent-list')).toBeAttached()
    await shoot(page, 'main')
  })

  await test.step('preferences', async () => {
    const { input } = await openSpeedPreferences(page)
    await expect(input).toBeAttached()
    await shoot(page, 'preferences-speed')
    await page.locator('#prefs-dialog .tabs-container-close').click()
    await expect(page.locator('#prefs-dialog')).toBeHidden()
  })

  await test.step('statistics', async () => {
    await openOverflowAction(page, 'show-statistics-dialog')
    await expect(page.locator('.statistics-dialog')).toBeVisible()
    await shoot(page, 'statistics')
  })
})
