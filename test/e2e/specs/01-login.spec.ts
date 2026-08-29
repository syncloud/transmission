import { test } from '@playwright/test'
import { fillCredentials, signIn } from '../helpers/auth'
import { shoot } from '../helpers/screenshot'

test('authelia login form is served', async ({ page }, testInfo) => {
  await page.goto(`https://auth.${process.env.PLAYWRIGHT_FULL_DOMAIN ?? 'buster.com'}`)
  await fillCredentials(page)
  await shoot(page, testInfo, 'auth')
})

test('sign in through syncloud sso and reach the transmission ui', async ({ page }, testInfo) => {
  await page.goto('/')
  await shoot(page, testInfo, 'login')
  await signIn(page)
  await shoot(page, testInfo, 'main')
})
