const fs = require('fs')
const createDebug = require('debug')
const runReplacements = require('./run-replacements')

const debug = createDebug('i3-monitor')
const debugLine = debug.extend('line')
const debugTime = debug.extend('time')

const MIN_TIME = 10

module.exports = function gatherUsage(filename) {
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
    `${Math.round(Date.now() / 1000)} END : none`,
  )

  const today = new Date()
  today.setHours(0, 0, 0, 0)
  let last = {
    ts: Math.round(today.getTime() / 1000),
    className: 'MIDNIGHT',
    title: 'none',
  }
  let locked = false
  function parseLine(line) {
    try {
      return JSON.parse(line)
    } catch (e) {
      const a = line.indexOf(' ')
      const b = line.indexOf(':')
      const ts = Number(line.substr(0, a))

      if (ts > 0) {
        return {
          ts,
          title: line.substr(b + 1).trim(),
          className: line.substr(a, b - a).trim(),
        }
      }
    }
    return { ts: 0 }
  }

  const data = lines.reduce((memo, line) => {
    const tmp = parseLine(line)

    if (tmp.ts > 0 && tmp.ts >= last.ts) {
      const record = runReplacements(tmp)
      // const { ts, title, className } = runReplacements(tmp);
      const time = record.ts - last.ts

      if (!record.className) {
        console.error(line)
        debug('missing className')
      }

      if (record.className === 'UNLOCK') {
        if (!locked) {
          last = record
          return memo
        }
      }
      if (locked) {
        if (record.className === 'UNLOCK') {
          locked = false
        } else {
          return memo
        }
      }
      if (time < MIN_TIME) {
        return memo
      }

      debugLine(time, line)
      if (!last.className) {
        debug('Missing className', last)
      }

      // eslint-disable-next-line no-param-reassign
      memo[last.className] = memo[last.className] || { name: last.className, total: 0, titles: {} }
      // eslint-disable-next-line no-param-reassign
      memo[last.className].total += time
      debugTime(last.className, last.title, '+', time)

      const { titles } = memo[last.className]
      titles[last.title] = titles[last.title] || 0
      titles[last.title] += time

      if (record.className === 'LOCK') {
        locked = true
        last = {
          ...record,
          beforeLock: last.className,
        }
      } else if (record.className === 'UNLOCK') {
        last = {
          ...record,
          // When I unlock my computer in the morning, there isn't a matching
          // LOCK record, so beforeUnlock is undefined.
          className: last.beforeLock || last.className,
        }
      } else {
        last = record
      }
    }

    return memo
  }, {})

  const sorted = Object.keys(data)
    .map(key => data[key])
    .sort((a, b) => b.total - a.total)
  return sorted
}
