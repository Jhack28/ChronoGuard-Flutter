
const { Builder } = require('selenium-webdriver');

(async function testFirefox() {
  let driver = await new Builder().forBrowser('firefox').build();
  try {
    await driver.get('http://localhost:54232/#/adminHome:3000'); // Cambia a la URL de tu app web
    const title = await driver.getTitle();
    console.log('Título:', title);
    // Aquí puedes agregar más interacciones
  } finally {
    await driver.quit();
  }
})();
