/* eslint-disable no-console */
const os = require('os')
const path = require('path')
const fs = require('fs')
const activeWin = require('active-win')
const program = require('commander')
const createDebug = require('debug')
const i3 = require('i3')
const runReplacements = require('./run-replacements')
const gatherUsage = require('./gather-usage')
const { toTime } = require('./utils')

const debug = createDebug('i3-monitor')
const debugEvent = debug.extend('event')
const debugReport = debug.extend('report')

const filename = path.join(os.homedir(), 'personal_events.log')
// https://github.com/jaagr/polybar/wiki/Formatting#foreground-color-f
const reset = '%{F-}'
const red = '%{F#f00}'

program
  .version('0.1.0')
  .option('--monitor', `Monitor and write to ${filename}`)
  .option('--poll', 'poll with active-win instead of using i3 events')
  .option('--tail', 'tail')
  .option('--debug', `do not write to ${filename}`)
  .option('--verbose', 'verbose')
  .parse(process.argv)


function reportUsage() {
  const data = gatherUsage(filename)
    .filter(d => (
      ['MIDNIGHT', 'LOCK'].indexOf(d.name) === -1
      && d.total > 60
    ))

  // eslint-disable-next-line no-shadow
  const total = data.reduce((total, record) => (
    total + record.total
  ), 0)


  data.length = Math.min(data.length, 3)

  // eslint-disable-next-line no-shadow
  const report = data.map(({ name, total }) => `${name} ${toTime(total)}`)

  if (report.length === 0) {
    report.push(`${red}Nothing found`)
  } else {
    report.unshift(`TOTAL ${toTime(total, true)}`)
  }

  debugReport(report)
  // eslint-disable-next-line no-console
  console.log(report.join(`${reset} | `))
}


function verboseUsage() {
  const data = gatherUsage(filename)

  // eslint-disable-next-line no-shadow
  const total = data.reduce((total, record) => (
    total + record.total
  ), 0)

  console.log('TOTAL:', toTime(total, true))
  // eslint-disable-next-line no-shadow
  data.forEach(({ name, total, titles }) => {
    console.log(toTime(total, true), name)
    const emptyTitles = ['none', '']
    const titleKeys = Object.keys(titles).sort((a, b) => (
      titles[b] - titles[a]
    )).filter(
      key => emptyTitles.indexOf(key) === -1,
    )

    titleKeys.forEach((key) => {
      console.log('  ', toTime(titles[key]), key)
    })
  })
}

function logWindow(data) {
  const record = runReplacements(data)
  const line = JSON.stringify(record)
  console.log(line)
  if (!program.debug) {
    fs.appendFile(filename, `${line}\n`, (err) => {
      if (err) throw err
    })
  }
}

if (program.poll) {
  const isWin = process.platform === 'win32'
  let event = {}
  let locked = false
  setInterval(() => {
    const ts = Math.floor(Date.now() / 1000)
    if (isWin) {
      // eslint-disable-next-line global-require
      const lockYourWindows = require('lock-your-windows')
      const isLocked = lockYourWindows.isLocked()

      if (locked !== isLocked) {
        locked = isLocked
        if (isLocked) {
          logWindow({ ts, className: 'LOCK', title: '' })
          return
        }
        logWindow({ ts, className: 'UNLOCK', title: '' })
      } if (locked) {
        // Don't record any events if the console is locked
        return
      }
    }

    let win
    try {
      win = activeWin.sync()
    } catch (e) {
      console.error(e)
      return
    }
    if (event.title === win.title && event.className === win.owner.name) {
      return
    }
    event = {
      ts,
      className: win.owner.name,
      title: win.title,
    }
    logWindow(event)
  }, 1000)
} else if (program.monitor) {
  const client = i3.createClient()
  client.on('window', (event) => {
    debugEvent(event)
    if (event.change === 'title' || event.change === 'focus') {
      logWindow({
        ts: Math.floor(Date.now() / 1000),
        className: event.container.window_properties.class,
        title: event.container.window_properties.title,
      })
    }
  })
} else if (program.tail) {
  reportUsage()
  setInterval(reportUsage, 10 * 1000)
} else if (program.verbose) {
  verboseUsage()
} else {
  reportUsage()
}
