import { expect, Locator, Page } from '@playwright/test'

export async function openOverflowAction(page: Page, action: string) {
  await page.locator('#toolbar-overflow').click()
  const button = page.locator(`button[data-action="${action}"]`)
  await expect(button).toBeVisible()
  await button.click()
}

export async function openSpeedPreferences(page: Page): Promise<{ check: Locator, input: Locator }> {
  await openOverflowAction(page, 'show-preferences-dialog')
  const dialog = page.locator('#prefs-dialog')
  await expect(dialog).toBeVisible()
  await dialog.locator('#prefs-tab-speed').click()
  const check = dialog.locator('#upload-speed-div input[type="checkbox"]')
  const input = dialog.locator('#upload-speed-div + input[type="number"]')
  await expect(check).toBeVisible()
  return { check, input }
}
