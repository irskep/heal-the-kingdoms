var browserify = require('browserify');
var gulp = require('gulp');
var clean = require('gulp-clean');
var connect = require('gulp-connect');
var rename = require('gulp-rename');
var sass = require('gulp-ruby-sass');
var source = require('vinyl-source-stream');
var stringify = require('stringify');
var uglify = require('gulp-uglify');
var yamlify = require('yamlify');

gulp.task('clean', function () {
  return gulp.src('build/**/*.*', {read: false})
    .pipe(clean())
});

gulp.task('sass', ['copy'], function() {
  return gulp.src('src/*.scss')
    .pipe(sass({ style: 'compressed' }))
    .pipe(gulp.dest('build/css/'))
    .pipe(connect.reload());
});


gulp.task('browserify', function() {
  var bundleStream = browserify({
      basedir: '.', extensions: ['.js', '.coffee'], debug: true
  }).add('./index.coffee')
    .transform('coffee-reactify')
    .transform(yamlify)
    .transform(stringify(['.txt', '.scss']))
    .bundle()
    .on('error', function (err) {
      if (err) {
        console.error(err.toString());
      }
   })

  return bundleStream
    .pipe(source('index.coffee'))
    .pipe(rename('heal-the-kingdoms.js'))
    .pipe(gulp.dest('./build/'))
    .pipe(connect.reload());
});


gulp.task('uglify', ['browserify'], function() {
  return gulp.src('./build/heal-the-kingdoms.js')
    .pipe(uglify())
    .pipe(rename('heal-the-kingdom  s.min.js'))
    .pipe(gulp.dest('./build/'));
});

gulp.task('copy', function() {
  gulp.src('./static/**/*', {base: './static/'})
    .pipe(gulp.dest('./build/'))
    .pipe(connect.reload());
});

gulp.task('default', ['uglify', 'sass', 'copy'], function() {
});

gulp.task('watch', function() {
  gulp.watch(['*.coffee', 'src/**/*.coffee'], ['browserify']);
  gulp.watch('*/*.scss', ['sass']);
  gulp.watch('static/**/*.*', ['copy']);
});


gulp.task('serve', function() {
  connect.server({
    root: 'build',
    livereload: {port: 35728}
  });
});


gulp.task('dev', ['copy', 'browserify', 'sass', 'watch', 'serve'], function() {
});
