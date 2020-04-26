module.exports = {
  launch: {
    headless: process.env.HEADLESS !== 'false',
  },
  server: {
    command: 'cd .. && MIX_ENV=integration mix integration',
    port: 4001,
  },
};
