import assert from 'assert';
import puppeteer from 'puppeteer';

const langOverrides = { dart: 'google' };
let lang = process.env.SQL_FORMATTER_LANG.toLowerCase().trim();
lang = langOverrides[lang] || lang;

const input = "select * from users as u join roles as r on u.id = r.user_id where u.email like '%gmail.com' and u.first_name = 'John';";
const expectedOutput = numSpaces =>
  `SELECT *\nFROM users AS u\nJOIN roles AS r\n${' '.repeat(numSpaces)}ON u.id = r.user_id\n` +
  `WHERE u.email LIKE '%gmail.com'\n${' '.repeat(numSpaces)}AND u.first_name = 'John';`;

describe(`SQL formatting using ${lang}`, () => {
  let browser;
  let page;

  const setInput = async (val, id) => await page.$eval(id || '#sql-input', (el, v) => {
    el.value = v;
    el.dispatchEvent(new Event('input'));
  }, val);

  const waitForOutput = async empty => {
    await page.waitForFunction(`document.getElementById('sql-output').value ${empty ? '===' : '!=='} ''`);
    return await page.$eval('#sql-output', el => el.value);
  }

  before(async function () {
    this.timeout(10000);
    browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
    page = await browser.newPage();
    await page.goto(`http://localhost:8000/?lang=${lang}`);
    await page.waitForSelector('#sql-input');
  });

  beforeEach(async () => {
    await setInput('');
    await setInput(2, '#sql-spaces');
    await waitForOutput(true);
  });

  after(async () => browser && browser.close());

  it('formats SQL correctly with 2 spaces', async () => {
    await setInput(input);
    const output = await waitForOutput(false);
    assert.equal(output, expectedOutput(2));
  });

  it('formats SQL correctly with 4 spaces', async () => {
    await setInput(4, '#sql-spaces');
    await setInput(input);
    const output = await waitForOutput(false);
    assert.equal(output, expectedOutput(4));
  });

  const testSelection = event => async () => {
    await page.$eval('#sql-output', el => el.blur());
    await page.evaluate(() => window.getSelection().empty());
    const selected1 = await page.evaluate(() => window.getSelection().toString());
    assert.equal(selected1, '');

    await setInput(input);
    await waitForOutput(false);
    await page[event]('#sql-output');
    const selected2 = await page.evaluate(() => window.getSelection().toString());
    assert.equal(selected2, expectedOutput(2));
  };

  it('selects SQL output on click', testSelection('click'));
  it('selects SQL output on focus', testSelection('focus'));
});
