const clickAndWaitForNavigation = async (selector) => {
  await Promise.all([page.waitForNavigation(), page.click(selector)]);
};

describe('Create new user and log in', () => {
  it('Creates a new user, logs in, gets assigned a new villa, and logs out', async () => {
    await page.goto('http://localhost:4001');

    await clickAndWaitForNavigation('a[href="/players/new"]');

    await page.type('input[id="player_name"]', 'player');
    await page.type('input[id="player_email"]', 'player@example.com');
    await page.type('input[id="player_password"]', 'eKuSh4ahbuelienu');
    await page.type(
      'input[id="player_password_confirmation"]',
      'eKuSh4ahbuelienu'
    );

    await clickAndWaitForNavigation('button[type="submit"]');

    await clickAndWaitForNavigation('a[href="/session/new"]');

    await page.type('input[id="session_email"]', 'player@example.com');
    await page.type('input[id="session_password"]', 'eKuSh4ahbuelienu');

    await clickAndWaitForNavigation('button[type="submit"]');

    expect(await page.$$('a[href="/villas/1"]')).toHaveLength(2);

    await page.click('span.glyphicon-user');
    await clickAndWaitForNavigation('ul.dropdown-menu a[href="#"]');
  });
});
