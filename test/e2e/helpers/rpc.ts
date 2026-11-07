import { Page } from '@playwright/test'

export async function rpc(page: Page, method: string, args: Record<string, unknown> = {}): Promise<any> {
  return page.evaluate(async ({ method, args }) => {
    const body = JSON.stringify({ method, arguments: args })
    let headers: Record<string, string> = { 'Content-Type': 'application/json' }
    let response = await fetch('/transmission/rpc', { method: 'POST', headers, body })
    if (response.status === 409) {
      headers = { ...headers, 'X-Transmission-Session-Id': response.headers.get('X-Transmission-Session-Id') ?? '' }
      response = await fetch('/transmission/rpc', { method: 'POST', headers, body })
    }
    if (!response.ok) {
      throw new Error(`${method}: HTTP ${response.status}`)
    }
    const json = await response.json()
    if (json.result !== 'success') {
      throw new Error(`${method}: ${json.result}`)
    }
    return json.arguments
  }, { method, args })
}
