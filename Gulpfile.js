var gulp = require('gulp')
var coffee = require('gulp-coffee')
var concat = require('gulp-concat')
var prepend = require('gulp-insert').prepend
var shell = require('gulp-shell')
var uglify = require('gulp-uglify')
var rename = require('gulp-rename')
var fs = require('fs')

gulp.task('build', function() {
  // Order here is important.
  files = [
    './src/setup.coffee',
    './src/assert.coffee',
    './src/id_factory.coffee',
    './src/action.coffee',
    './src/dispatcher.coffee',
    './src/deferred_task.coffee',
    './src/store.coffee',
    './src/export.coffee'
  ]

  gulp.src(files)
      .pipe(concat('hippodrome.js'))
      .pipe(coffee())
      .pipe(gulp.dest('./dist'))
      .pipe(uglify())
      .pipe(rename('hippodrome.min.js'))
      .pipe(gulp.dest('./dist'))
});

gulp.task('test', ['build'], shell.task([
  'npm run test'
]))

gulp.task('watch', ['test'], function() {
  gulp.watch('src/**/*.coffee', ['test']);
})

gulp.task('set-npm-version', function() {
  version = require('./package.json').version;
  pkg = fs.readFileSync('./npm/package.json')
  pkgJson = JSON.parse(pkg)
  pkgJson.version = version
  fs.writeFileSync('./npm/package.json', JSON.stringify(pkgJson, null, 2))
})

gulp.task('copy-npm-javascript', function() {
  gulp.src('dist/*.js')
      .pipe(gulp.dest('./npm'))
})

gulp.task('prepare-npm', ['set-npm-version', 'copy-npm-javascript'])

gulp.task('set-gem-version', function() {
  version = require('./package.json').version;
  gemVersionModule = 'module Hippodrome\n  VERSION = \'' + version + '\'\nend'
  fs.writeFileSync('./rails/lib/hippodrome/version.rb', gemVersionModule)
})

gulp.task('copy-gem-javascript', function() {
  gulp.src('dist/*/js')
      .pipe(prepend('//= require lodash\n\n')) // Sprockets directive for rails.
      .pipe(gulp.dest('./rails/app/assets/javascripts'))
})

gulp.task('prepare-gem', ['set-gem-version', 'copy-gem-javascript'])

gulp.task('commit-version-changes', ['prepare-gem', 'prepare-npm'], function() {
  version = require('./package.json').version;

  gulp.src('')
      .pipe(shell([
        'git add npm/package.json rails/lib/hippodrome/version.rb',
        'git commit -m "Build version ' + version + ' of hippodrome."'
      ]))
})

gulp.task('publish', ['commit-version-changes'])
