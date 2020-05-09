describe('Create new user and log in', () => {
  it('Creates a new user, logs in, builds a building in a newly assigned villa', async () => {
    await page.goto('http://localhost:4001');

    await Promise.all([
      page.click('a[href="/players/new"]'),
      page.waitForNavigation(),
    ]);

    await page.type('input[id="player_name"]', 'player');
    await page.type('input[id="player_email"]', 'player@example.com');
    await page.type('input[id="player_password"]', 'eKuSh4ahbuelienu');
    await page.type(
      'input[id="player_password_confirmation"]',
      'eKuSh4ahbuelienu'
    );

    await Promise.all([
      page.click('button[type="submit"]'),
      page.waitForNavigation(),
    ]);

    await Promise.all([
      page.click('a[href="/session/new"]'),
      page.waitForNavigation(),
    ]);

    await page.type('input[id="session_email"]', 'player@example.com');
    await page.type('input[id="session_password"]', 'eKuSh4ahbuelienu');

    await Promise.all([
      page.click('button[type="submit"]'),
      page.waitForNavigation(),
    ]);

    expect(await page.$$('a[href="/villas/1"]')).toHaveLength(2);

    await page.click('span.glyphicon-user');
    await Promise.all([
      page.click('ul.dropdown-menu a[href="/session"]'),
      page.waitForNavigation(),
    ]);

    await Promise.all([
      page.click('a[href="/session/new"]'),
      page.waitForNavigation(),
    ]);

    await page.type('input[id="session_email"]', 'player@example.com');
    await page.type('input[id="session_password"]', 'eKuSh4ahbuelienu');

    await Promise.all([
      page.click('button[type="submit"]'),
      page.waitForNavigation(),
    ]);

    await Promise.all([
      page.click('a[href="/villas/1"]'),
      page.waitForNavigation(),
    ]);

    await Promise.all([
      page.click('a[href="/villas/1/building_queue_items?building_id=1"]'),
      page.waitForNavigation(),
    ]);
  });
});
