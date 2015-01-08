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
    './src/startup.coffee',
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

gulp.task('watch', [], function() {
  gulp.watch('src/**/*.coffee', ['test']);
  gulp.watch('test/**/*.coffee', ['test']);
})

gulp.task('set-npm-version', function() {
  version = require('./package.json').version;
  pkg = fs.readFileSync('./npm/package.json')
  pkgJson = JSON.parse(pkg)
  pkgJson.version = version
  fs.writeFileSync('./npm/package.json', JSON.stringify(pkgJson, null, 2))
})

gulp.task('copy-npm-javascript', function() {
  return gulp.src('dist/*.js')
             .pipe(gulp.dest('./npm'))
})

gulp.task('copy-npm-metafiles', function() {
  return gulp.src(['README.md'])
             .pipe(gulp.dest('./npm'))
})

gulp.task('prepare-npm', ['set-npm-version', 'copy-npm-javascript', 'copy-npm-metafiles'])

gulp.task('set-gem-version', function() {
  version = require('./package.json').version;
  gemVersionModule = 'module Hippodrome\n  VERSION = \'' + version + '\'\nend'
  fs.writeFileSync('./rails/lib/hippodrome/version.rb', gemVersionModule)
})

gulp.task('copy-gem-javascript', function() {
  return gulp.src('dist/*.js')
             .pipe(prepend('//= require lodash\n\n')) // Sprockets directive for rails.
             .pipe(gulp.dest('./rails/app/assets/javascripts'))
})

gulp.task('copy-gem-metafiles', function() {
  return gulp.src(['LICENSE.txt', 'README.md'])
             .pipe(gulp.dest('./rails'))
})

gulp.task('prepare-gem', ['set-gem-version', 'copy-gem-javascript', 'copy-gem-metafiles'])

gulp.task('set-bower-version', function() {
  version = require('./package.json').version
  bowerJson = JSON.parse(fs.readFileSync('./bower.json'))
  bowerJson.version = version
  fs.writeFileSync('./bower.json', JSON.stringify(bowerJson, null, 2))
})

gulp.task('copy-bower-javascript', function() {
  return gulp.src('dist/*.js')
             .pipe(gulp.dest('./bower'))
})

gulp.task('prepare-bower', ['set-bower-version', 'copy-bower-javascript'])

gulp.task('commit-version-changes', ['prepare-gem', 'prepare-npm', 'prepare-bower'], function() {
  version = require('./package.json').version;

  gulp.src('')
      .pipe(shell([
        'git add npm/package.json npm/README.md rails/lib/hippodrome/version.rb rails/LICENSE.txt rails/README.md ./bower.json bower/*.js',
        'git commit -m "Build version ' + version + ' of hippodrome."'
      ]))
})

gulp.task('release-gem', ['commit-version-changes'], shell.task([
  'rake build',
  'rake release'
], {cwd: './rails'}))

// Strictly speaking, this doesn't depend on releasing the gem, but I want them
// to run in order.
gulp.task('publish-npm', ['release-gem'], shell.task([
  'npm publish'
], {cwd: './npm'}))

// Pretend there's a publish-bower task here.  We don't need it because
// release-gem will create and push the right tags for bower.

gulp.task('publish', ['publish-npm'])
