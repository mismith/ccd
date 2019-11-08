#!/usr/bin/env node

const path = require('path');
const { execSync } = require('child_process');
const { stdin, stdout, stderr } = process;
const readline = require('readline');

// this script does a weird thing with stdout vs. stderr: since it needs to emit the selected path
// back to the shell script's context (via stdout), it internally uses stderr to output it's 'GUI'
(async () => {
  let cwd = process.cwd();
  let files = [];
  let currentIndex = 0;
  const indexCache = {};

  readline.emitKeypressEvents(stdin);
  stdin.setRawMode(true);

  function ls(detailed = false) {
    try {
      // `2>/dev/null` gobbles up the output when the dir contains no sub-dirs
      return execSync(`ls -${detailed ? 'l' : ''}d */ 2>/dev/null`, { cwd }).toString().split('\n');
    } catch (err) {
      return [];
    }
  }
  function draw() {
    readline.cursorTo(stderr, 0, 0);
    readline.clearScreenDown(stderr);

    stderr.write(`${cwd}\n`);

    files = ls(true).filter(Boolean);
    files.forEach((line, index) => {
      const isHighlighted = index === currentIndex;
      stderr.write(`  ${isHighlighted ? '\x1b[7m' : ''}${line}${isHighlighted ? '\x1b[0m' : ''}\n`);
    });
  }

  // bump existing terminal commands out of view (since they will be covered by draw)
  // @TODO: getWindowSize fails in non-TTY
  // stderr.write(new Array(stderr.getWindowSize()[1]).join('\n')); 
  draw();

  stdin.on('keypress', (str, key) => {
    if ((key.ctrl && key.name === 'c') || key.name === 'escape') {
      return process.exit();
    }

    switch (key.name ) {
      case 'up': {
        currentIndex = (files.length + currentIndex - 1) % files.length;
        indexCache[cwd] = currentIndex;
        draw();
        break;
      }
      case 'down': {
        currentIndex = (currentIndex + 1) % files.length;
        indexCache[cwd] = currentIndex;
        draw();
        break;
      }
      case 'left': {
        cwd = path.resolve(path.join(cwd, '..'));
        currentIndex = indexCache[cwd] || 0;
        draw();

        break;
      }
      case 'right': {
        const nextDir = ls()[currentIndex];
        cwd = path.resolve(path.join(cwd, nextDir));
        currentIndex = indexCache[cwd] || 0;
        draw();
        break;
      }
      case 'return': {
        const nextDir = ls()[currentIndex];
        cwd = path.resolve(path.join(cwd, nextDir));

        // fall through to 'space'
      }
      case 'space': {
        stdout.write(cwd);
        process.exit();
        break;
      }
      default: {
        // ignore
        break;
      }
    }
  });
})();
