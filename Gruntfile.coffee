# Zum Ausführen:
# "grunt" bzw. "grunt default" 
module.exports = (grunt) ->
  grunt.initConfig
    clean: ['bower_components', 'js', 'lib', 'styles', 'index.html']
    #
    # bower
    bower:
      install:
        options:
          layout: 'byComponent'
          targetDir: "lib"
          cleanTargetDir: true
          #cleanup: true # both cleanBowerDir & cleanTargetDir are set to the value of cleanup.
    #
    # jade
    jade:
      compile:
        options:
          pretty: true
        files:
          'index.html': 'jade/index.jade'
    #
    # coffeescript
    coffee:
      compile:
        expand: true
        cwd: 'coffee'
        src: ['*.coffee']
        dest: 'js'
        ext: '.js'
    # grunt sass
    sass:
      dist:
        expand: true
        cwd: 'sass'
        src: ['*.sass']
        dest: 'styles'
        ext: '.css'
    #
    # watch
    watch:
      jade:
        files: ['jade/*']
        tasks: ['jade']
      coffee:
        files: ['coffee/*']
        tasks: ['coffee'] 
      sass:
        files: ['sass/*.sass']
        tasks: ['sass']
      livereload:
        files: ['js/*', 'styles/*', 'index.html']
        options:
          livereload: true

  grunt.loadNpmTasks('grunt-bower-task')
  grunt.loadNpmTasks('grunt-contrib-jade')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-sass')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-contrib-clean')

  grunt.registerTask('build', ['clean', 'bower:install', 'jade', 'coffee', 'sass'])
