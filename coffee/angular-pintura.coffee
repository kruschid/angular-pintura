module = angular.module('ngPintura', [])

# access to global paper object
module.value('ngpKonva', window.Konva)

###*
# pintura container
# creates and shares paperjs scope with child directives
# creates canvas
###
module.directive 'ngPintura', (ngpKonva, $window) ->
  directive = 
    transclude: true
    scope:
      src: '='
      scale: '='
      position: '='
      fitOnload: '='
    link: (scope, element, attrs, ctrl, transcludeFn) ->
      # konva stage
      stage = undefined
      # konva layer
      layer = undefined
      # image object
      image = 
        # konva image
        shape: undefined
        # konva tween (to fit image within bound)
        tween: undefined
        # scale boundaries
        minScale: 0.5
        maxScale: 5
        scaleStep: 0.1
        fitScale: (scale) -> Math.min(Math.max(scale, @minScale), @maxScale)
      # indicator object
      indicator = 
        # konva rect
        shape: undefined
        # konva animation
        animation: undefined
      # slider value an conversion functions
      slider =
        # current slider value
        value: undefined
        # sets slider value by passing scale
        fromScale: (scale) -> @value = parseInt(((scale-image.minScale)/(image.maxScale-image.minScale))*100)
        # returns corresponding scale value to current slider value
        toScale: -> (image.maxScale-image.minScale) * (@value/100) + image.minScale 

      # creates stage and items
      initStage = ->
        # create container
        container = angular.element('<div>')
        element.append(container)
        # create konva stage and items
        stage = new ngpKonva.Stage
          container: container[0]
          width: element[0].clientWidth
          height: element[0].clientHeight
        layer = new ngpKonva.Layer()
        image.shape = new ngpKonva.Image
          draggable: true
        indicator.shape = new ngpKonva.Rect()
        # create hierarchy
        stage.add(layer)
        layer.add(image.shape)
        layer.add(indicator.shape)

      # set indicator attributes and creates indicator animation
      initIndicator = ->
        indicator.shape.setAttrs
          x: stage.width()/2
          y: stage.height()/2
          width: 50
          height: 50
          fill: 'pink'
          stroke: 'white'
          strokeWidth: 4
          zIndex: 99
          visible: false
          offset:
              x: 25
              y: 25
        # define indicator animation
        animFn = (frame)->
          speed = 270 # degrees per second
          angleDiff = frame.timeDiff * speed / 1000
          indicator.shape.rotate(angleDiff)
        # register animation
        indicator.animation = new ngpKonva.Animation(animFn, layer)

      # changes size of stage according to new element size
      resizeStage = ->
        stage.size
          width: element[0].clientWidth
          height: element[0].clientHeight
        indicator.shape.position
          x: stage.width()/2
          y: stage.height()/2

      # loads new image and shows loading indicator 
      imageChange = ->
        ngpKonva.Image.fromURL(scope.src, imageLoad)
        indicator.shape.visible(true)
        indicator.animation.start()

      # inserts new image and hides loading indicator
      imageLoad = (newImage) ->
        image.shape.size(newImage.size())
        image.shape.image(newImage.image())
        newImage.destroy()
        indicator.shape.visible(false)
        indicator.animation.stop()
        layer.draw()

      # performs zoom to point based on mousewheel event
      mouseWheel = (e) ->
        e.evt.preventDefault() 
        if e.evt.wheelDeltaY > 0
          scope.scale += 0.1
        else
          scope.scale -= 0.1
        # perform zoom to point
        zoomToPoint(stage.getPointerPosition())
        # # keeps angular scope synchronized
        # scope.$apply()

      # performs zoom zo point
      zoomToPoint = (absPoint) ->
        # keep scale within bounds 
        scope.scale = image.fitScale(scope.scale)
        # translate point to local coordinates
        point = image.shape.getAbsoluteTransform().copy().invert().point(absPoint)
        # set new position: current position minus distance between current scaled point and point with new scale
        scope.position =         
          x: -point.x + absPoint.x/scope.scale
          y: -point.y + absPoint.y/scope.scale
        # perform animation
        adjust()

      # perform animation to new scale and position
      adjust = ->
        # do not run this method if if pos or scale is not a number
        return if isNaN(scope.position.x) or isNaN(scope.position.y) or isNaN(scope.scale)
        # if new pos is different from current pos
        if scope.scale isnt layer.scaleX() or scope.position.x*scope.scale isnt layer.x() or scope.position.y*scope.scale isnt layer.y()
          # freeze state and destroy prior animation
          # !!! do not use finish() here, it'll cause adoptation of prior tween state !!
          # at least onFinish will be fired because after pause and destroy the tween is getting started again
          image.tween.pause().destroy() if image.tween
          # create position tween
          image.tween = new ngpKonva.Tween
            x: scope.position.x * scope.scale # multiplication is obligatory because in the new state the image is bigger/smaller
            y: scope.position.y * scope.scale
            scaleX: scope.scale
            scaleY: scope.scale
            node: image.shape
            duration: 0.25
            easing: ngpKonva.Easings.EaseOut
            onFinish: ->
              # teile angular mit, dass scope modifiziert wurde
              scope.$apply()
        # start animation
        image.tween.play()

      # contructor
      initStage()
      initIndicator()
      scope.$watch('src', imageChange)
      angular.element($window).on('resize', resizeStage)
      image.shape.on('mousewheel', mouseWheel)
      # pass scope into transcluded template
      transcludeFn( scope, (clonedTranscludedTemplate) -> element.append(clonedTranscludedTemplate) )