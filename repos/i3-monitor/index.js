/* eslint-disable no-console */
const os = require('os');
const fs = require('fs');
const path = require('path');
const program = require('commander');
const createDebug = require('debug');
const i3 = require('i3');

const debug = createDebug('i3-monitor');
const debugLine = debug.extend('line');
const debugEvent = debug.extend('event');
const debugReport = debug.extend('report');
const debugTime = debug.extend('time');

const MIN_TIME = 10;
const filename = '/home/asa/personal_events.log';
// https://github.com/jaagr/polybar/wiki/Formatting#foreground-color-f
const reset = '%{F-}';
const red = '%{F#f00}';

program
  .version('0.1.0')
  .option('-p, --monitor', `Monitor and write to ${filename}`)
  .option('-t, --tail', 'tail')
  .option('-d, --debug', `do not write to ${filename}`)
  .option('-v, --verbose', 'verbose')
  .parse(process.argv);

let transforms = [];
const configFilename = path.join(os.homedir(), '.i3-monitor.json');
if (fs.existsSync(configFilename)) {
  transforms = JSON.parse(fs.readFileSync(configFilename));
}

function runReplacements(record) {
  // eslint-disable-next-line no-shadow
  return transforms.reduce((record, transform) => {
    if (typeof transform.title === 'string') {
      // eslint-disable-next-line no-param-reassign
      transform.title = new RegExp(transform.title);
    }
    if (typeof transform.className === 'string') {
      // eslint-disable-next-line no-param-reassign
      transform.className = [transform.className];
    }

    const matchClass = (
      transform.className == null
        || transform.className.indexOf(record.className) >= 0
    );
    const match = record.title.match(transform.title);

    if (matchClass && match) {
      const title = record.title.replace(transform.title, transform.replaceTitle);

      let { className } = record;
      if (transform.replaceClass) {
        className = transform.replaceClass.replace(
          /\$(\d)/,
          (full, digit) => match[digit],
        );
      }

      return {
        ...record,
        className,
        title,
      };
    }
    return record;
  }, record);
}

function gatherUsage() {
  let lines = [];
  try {
    lines = String(fs.readFileSync(filename))
      .split('\n');
  } catch (e) {
    if (e.code === 'ENOENT') {
      console.log('~/personal_events.log not found');
      process.exit(1);
    }
    throw e;
  }
  lines.push(
    `${Math.round(Date.now() / 1000)} END : none`,
  );

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  let last = {
    ts: Math.round(today.getTime() / 1000),
    className: 'MIDNIGHT',
    title: 'none',
  };
  let locked = false;
  function parseLine(line) {
    try {
      return JSON.parse(line);
    } catch (e) {
      const a = line.indexOf(' ');
      const b = line.indexOf(':');
      const ts = Number(line.substr(0, a));

      if (ts > 0) {
        return {
          ts,
          title: line.substr(b + 1).trim(),
          className: line.substr(a, b - a).trim(),
        };
      }
    }
    return { ts: 0 };
  }

  const data = lines.reduce((memo, line) => {
    const tmp = parseLine(line);

    if (tmp.ts > 0 && tmp.ts >= last.ts) {
      const record = runReplacements(tmp);
      // const { ts, title, className } = runReplacements(tmp);
      const time = record.ts - last.ts;

      if (!record.className) {
        console.error(line);
        debug('missing className');
      }

      if (locked) {
        if (record.className === 'UNLOCK') {
          locked = false;
        } else {
          return memo;
        }
      }
      if (time < MIN_TIME) {
        return memo;
      }

      debugLine(time, line);
      if (!last.className) {
        debug('Missing className', last);
      }

      // eslint-disable-next-line no-param-reassign
      memo[last.className] = memo[last.className] || { name: last.className, total: 0, titles: {} };
      // eslint-disable-next-line no-param-reassign
      memo[last.className].total += time;
      debugTime(last.className, last.title, '+', time);

      const { titles } = memo[last.className];
      titles[last.title] = titles[last.title] || 0;
      titles[last.title] += time;

      if (record.className === 'LOCK') {
        locked = true;
        last = {
          ...record,
          beforeLock: last.className,
        };
      } else if (record.className === 'UNLOCK') {
        last = {
          ...record,
          // When I unlock my computer in the morning, there isn't a matching
          // LOCK record, so beforeUnlock is undefined.
          className: last.beforeLock || last.className,
        };
      } else {
        last = record;
      }
    }

    return memo;
  }, {});

  const sorted = Object.keys(data)
    .map(key => data[key])
    .sort((a, b) => b.total - a.total);
  return sorted;
}

function toTime(seconds, padding = false) {
  let minutes = Math.floor(seconds / 60);
  let hours = Math.floor(minutes / 60);
  minutes %= 60;

  minutes = String(minutes);
  if (padding) {
    hours = String(hours).padStart(2, '0');
  }

  if (hours > 0 || padding) {
    return `${hours}:${minutes.padStart(2, '0')}`;
  }
  return `${minutes.padStart(2, '0')}`;
}

function reportUsage() {
  const data = gatherUsage()
    .filter(d => (
      ['MIDNIGHT', 'LOCK'].indexOf(d.name) === -1
      && d.total > 60
    ));

  // eslint-disable-next-line no-shadow
  const total = data.reduce((total, record) => (
    total + record.total
  ), 0);


  data.length = Math.min(data.length, 3);

  // eslint-disable-next-line no-shadow
  const report = data.map(({ name, total }) => `${name} ${toTime(total)}`);

  if (report.length === 0) {
    report.push(`${red}Nothing found`);
  } else {
    report.unshift(`TOTAL ${toTime(total, true)}`);
  }

  debugReport(report);
  // eslint-disable-next-line no-console
  console.log(report.join(`${reset} | `));
}


function verboseUsage() {
  const data = gatherUsage();

  // eslint-disable-next-line no-shadow
  const total = data.reduce((total, record) => (
    total + record.total
  ), 0);

  console.log('TOTAL:', toTime(total, true));
  // eslint-disable-next-line no-shadow
  data.forEach(({ name, total, titles }) => {
    console.log(toTime(total, true), name);
    const emptyTitles = ['none', ''];
    const titleKeys = Object.keys(titles).sort((a, b) => (
      titles[b] - titles[a]
    )).filter(
      key => emptyTitles.indexOf(key) === -1,
    );

    titleKeys.forEach((key) => {
      console.log('  ', toTime(titles[key]), key);
    });
  });
}

if (program.monitor) {
  const client = i3.createClient();
  client.on('window', (event) => {
    debugEvent(event);
    if (event.change === 'title' || event.change === 'focus') {
      const record = runReplacements({
        ts: Math.floor(Date.now() / 1000),
        className: event.container.window_properties.class,
        title: event.container.window_properties.title,
      });

      const line = JSON.stringify(record);

      console.log(line);
      if (!program.debug) {
        fs.appendFile(filename, `${line}\n`, (err) => {
          if (err) throw err;
        });
      }
    }
  });
} else if (program.tail) {
  reportUsage();
  setInterval(reportUsage, 10 * 1000);
} else if (program.verbose) {
  verboseUsage();
} else {
  reportUsage();
}
