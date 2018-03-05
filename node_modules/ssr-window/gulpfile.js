const gulp = require('gulp');
const connect = require('gulp-connect');
const open = require('gulp-open');
const header = require('gulp-header');
const uglify = require('gulp-uglify');
const sourcemaps = require('gulp-sourcemaps');
const rollup = require('rollup-stream');
const buble = require('rollup-plugin-buble');
const source = require('vinyl-source-stream');
const buffer = require('vinyl-buffer');
const rename = require('gulp-rename');
const modifyFile = require('gulp-modify-file');
const pkg = require('./package.json');

const date = (function date() {
  return {
    year: new Date().getFullYear(),
    month: ('January February March April May June July August September October November December').split(' ')[new Date().getMonth()],
    day: new Date().getDate(),
  };
}());
const banner = `
/**
 * SSR Window ${pkg.version}
 * ${pkg.description}
 * ${pkg.homepage}
 *
 * Copyright ${date.year}, ${pkg.author}
 *
 * Licensed under ${pkg.license}
 *
 * Released on: ${date.month} ${date.day}, ${date.year}
 */
`.trim();

// UMD DIST
function umd(cb) {
  const env = process.env.NODE_ENV || 'development';
  rollup({
    input: './src/ssr-window.js',
    plugins: [buble()],
    format: 'umd',
    name: 'ssrWindow',
    strict: true,
    sourcemap: env === 'development',
    banner,
  })
  .pipe(source('ssr-window.js', './src'))
  .pipe(buffer())
  .pipe(gulp.dest(`./${env === 'development' ? 'build' : 'dist'}/`))
  .on('end', () => {
    if (env === 'development') {
      if (cb) cb();
      return;
    }
    gulp.src('./dist/ssr-window.js')
    .pipe(sourcemaps.init())
    .pipe(uglify())
    .pipe(header(banner))
    .pipe(rename('ssr-window.min.js'))
    .pipe(sourcemaps.write('./'))
    .pipe(gulp.dest('./dist/'))
    .on('end', () => {
      if (cb) cb();
    });
  });
}
// ES MODULE DIST
function es(cb) {
  const env = process.env.NODE_ENV || 'development';
  rollup({
    input: './src/ssr-window.js',
    plugins: [buble()],
    format: 'es',
    name: 'ssrWindow',
    strict: true,
    sourcemap: env === 'development',
    banner,
  })
  .pipe(source('ssr-window.js', './src'))
  .pipe(buffer())
  .pipe(rename('ssr-window.esm.js'))
  .pipe(gulp.dest(`./${env === 'development' ? 'build' : 'dist'}/`))
  .on('end', () => {
    if (cb) cb();
  });
}

gulp.task('build', (cb) => {
  let cbs = 0;
  umd(() => {
    cbs += 1;
    if (cbs === 2) cb();
  });
  es(() => {
    cbs += 1;
    if (cbs === 2) cb();
  });
});

gulp.task('demo', (cb) => {
  const env = process.env.NODE_ENV || 'development';
  gulp.src('./demo/index.html')
    .pipe(modifyFile((content) => {
      if (env === 'development') {
        return content
          .replace('../dist/dom7.min.js', '../build/dom7.js');
      }
      return content
        .replace('../build/dom7.js', '../dist/dom7.min.js');
    }))
    .pipe(gulp.dest('./demo/'))
    .on('end', () => {
      if (cb) cb();
    });
});

gulp.task('watch', () => {
  gulp.watch('./src/*.js', ['build']);
});

gulp.task('connect', () => connect.server({
  root: ['./'],
  livereload: true,
  port: '3000',
}));

gulp.task('open', () => gulp.src('./demo/index.html').pipe(open({ uri: 'http://localhost:3000/demo/index.html' })));

gulp.task('server', ['watch', 'connect', 'open']);
