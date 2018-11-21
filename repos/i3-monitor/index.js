const fs = require('fs')
const program = require('commander')
const createDebug = require('debug')
const debug = createDebug('i3-monitor')
const debugLine = createDebug('i3-monitor:line')

const filename = '/home/asa/personal_events.log'
const reset = '%{F-}'
const red = '%{F#f00}'

program
  .version('0.1.0')
  .option('-p, --monitor', `Monitor and write to ${filename}`)
  .option('-t, --tail', 'tail')
  .option('-d, --debug', `do not write to ${filename}`)
  .parse(process.argv);

function reportUsage() {

  let lines = []
  try {
    lines = String(fs.readFileSync(filename))
      .split('\n')
  } catch (e) {
    if (e.code === 'ENOENT') {
      console.log('~/personal_events.log not found')
      process.exit(1)
    } 
    throw e
  }
  lines.push(
    Math.round(Date.now() / 1000) + ' END : none'
  )

  var today = new Date();
  today.setHours(0,0,0,0);
  let last = { 
    ts : Math.round(today.getTime() / 1000),
    className: 'MIDNIGHT',
    title: 'none',
  }
  debug(last.className, last.ts)
  const data = lines.reduce((memo, line) => {
    const a = line.indexOf(' ')
    const b = line.indexOf(':')

    const ts = Number(line.substr(0, a))
    if (ts > 0 && ts >= last.ts) {
      const className = line.substr(a, b - a).trim()
      const title = line.substr(b + 1).trim()
      if (last.ts > 0) {
        const time = ts - last.ts
        debugLine(ts, line)
        debug(last.className, '+', time, last.beforeLock)


        memo[last.className] = memo[last.className] || { name: last.className, total: 0, titles: {} }
        memo[last.className].total += time

        const { titles } = memo[last.className]
        titles[last.title] = titles[last.title] || 0
        titles[last.title] += time
      }

      if (className === 'LOCK') {
        last = {
          ...last,
          ts,
          className,
          title,
          beforeLock: last.className,
        }
      } else if (className === 'UNLOCK') {
        last = {
          ts,
          className: last.beforeLock,
          title
        }
      } else {
        last = {
          ts,
          className,
          title
        }
      }
    }

    return memo
  }, {})
  debug(data)

  delete data.MIDNIGHT

  const sortedKeys = Object.keys(data).sort((a, b) => 
    data[b].total - data[a].total
  ).filter(key => (
    data[key].total > 60
  ))

  const total = Object.keys(data).reduce((total, key) => (
    total + data[key].total
  ), 0)

  function toTime (seconds) {
    let minutes = Math.floor(seconds / 60)
    let hours = Math.floor(minutes / 60)
    minutes = minutes % 60

    minutes = String(minutes)
    hours = String(hours)
    if (hours > 0) {
      return `${hours.padStart(2, '0')}:${minutes.padStart(2, '0')}`
    } else {
      return `${minutes.padStart(2, '0')}`
    }
  }

  sortedKeys.length = Math.min(sortedKeys.length, 3)

  const report = sortedKeys.map(key => {
    return key + ' ' + toTime(data[key].total)
  })

  if (report.length === 0) {
    report.push(`${red}Nothing found`)
  } else {
    report.unshift(`TOTAL ${toTime(total)}`)
  }

  debug(report)
  console.log(report.join(`${reset} | `))
}


if (program.monitor) {
  const i3 = require('i3').createClient();
  i3.on('window', function(event) {
    debug(event)
    if (event.change === 'title' || event.change === 'focus') {
      const { class: windowClass, title } = event.container.window_properties
      const line = `${Math.floor(Date.now() / 1000)} ${windowClass} : ${title}`

      console.log(line);
      if (!program.debug) {
        fs.appendFile(filename, line + '\n', (err) => {
          if (err) throw err;
        })
      }
    }
  })
} else if (program.tail) {
  reportUsage()
  setInterval(reportUsage, 10 * 1000)
} else {
  reportUsage()
}
