const click = async (selector) => {
  await Promise.all([page.waitForNavigation(), page.click(selector)]);
};

describe('Create new user and log in', () => {
  it('Creates a new user, logs in, and gets assigned a new villa', async () => {
    await page.goto('http://localhost:4001');

    await click('a[href="/players/new"]');

    await page.type('input[id="player_name"]', 'player');
    await page.type('input[id="player_email"]', 'player@example.com');
    await page.type('input[id="player_password"]', 'eKuSh4ahbuelienu');
    await page.type(
      'input[id="player_password_confirmation"]',
      'eKuSh4ahbuelienu'
    );

    await click('button[type="submit"]');

    await click('a[href="/session/new"]');

    await page.type('input[id="session_email"]', 'player@example.com');
    await page.type('input[id="session_password"]', 'eKuSh4ahbuelienu');

    await click('button[type="submit"]');

    expect(await page.$$('a[href="/villas/1"]')).toHaveLength(2);
  });
});
